import { test, expect } from '@playwright/test';

const ADMIN_BASE_URL = process.env.ADMIN_BASE_URL || 'http://127.0.0.1:5174';
const PROFESSOR_BASE_URL = process.env.PROFESSOR_BASE_URL || 'http://127.0.0.1:5173';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL || 'admin@ua.pt';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD || 'admin123';

function uniqueSeed() {
  return `${Date.now()}${Math.floor(Math.random() * 1000)}`;
}

function findRequestCard(page, title) {
  return page
    .locator('div.bg-surface.rounded-card')
    .filter({ has: page.locator('h4', { hasText: title }) })
    .first();
}

function findApprovalCard(page, email) {
  return page.locator('article.bg-surface').filter({ hasText: email }).first();
}

async function expectConfirmationAndAccept(page, action, expectedText) {
  const dialogPromise = page.waitForEvent('dialog');
  const actionPromise = action();
  const dialog = await dialogPromise;
  if (expectedText) {
    expect(dialog.message()).toContain(expectedText);
  }
  await dialog.accept();
  await actionPromise;
}

async function loginAdmin(page) {
  await page.goto(ADMIN_BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.getByPlaceholder('nome@ua.pt').fill(ADMIN_EMAIL);
  await page.locator('input[placeholder="••••••••"]').first().fill(ADMIN_PASSWORD);
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByRole('link', { name: /Disciplinas/ })).toBeVisible();
}

async function loginProfessor(page, email, password) {
  await page.goto(PROFESSOR_BASE_URL, { waitUntil: 'domcontentloaded' });

  const logoutButton = page.getByRole('button', { name: 'Terminar Sessão' });
  if (await logoutButton.isVisible().catch(() => false)) {
    await logoutButton.click();
  }

  await page.getByPlaceholder('nome@ua.pt').fill(email);
  await page.locator('input[placeholder="••••••••"]').first().fill(password);
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByRole('link', { name: /Pedidos ao Admin/ })).toBeVisible();
}

async function registerProfessorViaUI(page, data) {
  await page.goto(PROFESSOR_BASE_URL, { waitUntil: 'domcontentloaded' });

  const logoutButton = page.getByRole('button', { name: 'Terminar Sessão' });
  if (await logoutButton.isVisible().catch(() => false)) {
    await logoutButton.click();
  }

  await expect(page.getByRole('button', { name: 'Criar Conta' })).toBeVisible();
  await page.getByRole('button', { name: 'Criar Conta' }).click();

  await page.getByPlaceholder('Nome completo').fill(data.name);
  await page.getByPlaceholder('Ex: 115000').fill(data.nmec);
  await page.getByPlaceholder('nome@ua.pt').fill(data.email);
  await page.getByPlaceholder('Mínimo 6 caracteres').fill(data.password);
  await page.getByPlaceholder('Repete a password').fill(data.password);

  await page.getByRole('button', { name: 'Enviar Pedido' }).click();
  await expect(page.getByText(/Pedido enviado com sucesso/i)).toBeVisible();
}

async function loginProfessorExpectPending(page, email, password) {
  await page.goto(PROFESSOR_BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.getByPlaceholder('nome@ua.pt').fill(email);
  await page.locator('input[placeholder="••••••••"]').first().fill(password);
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByText(/Conta em análise/i)).toBeVisible();
}

test.describe.serial('Admin + Professor critical web flows', () => {
  const seed = uniqueSeed();
  const professor = {
    name: `Docente E2E ${seed.slice(-6)}`,
    email: `docente.e2e.${seed}@ua.pt`,
    password: `E2E-${seed.slice(-8)}!`,
    nmec: seed.slice(-6),
  };
  const requestTitle = `Pedido E2E ${seed.slice(-5)}`;
  const requestDescription = 'Validacao E2E de pedido administrativo';
  const adminDecisionNote = `Aprovado E2E ${seed.slice(-4)}`;
  const ucCode = String(60000 + Number(seed.slice(-4)));
  const ucName = `UC E2E ${seed.slice(-4)}`;
  const ucAcronym = `E${seed.slice(-2)}`;

  test('Professor account requires admin approval before login and request workflow remains operational', async ({ browser }) => {
    const professorContext = await browser.newContext();
    const professorPage = await professorContext.newPage();

    await registerProfessorViaUI(professorPage, professor);
    await loginProfessorExpectPending(professorPage, professor.email, professor.password);

    await professorContext.close();

    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();

    await loginAdmin(adminPage);

    await adminPage.getByRole('link', { name: /Aprovações/ }).click();
    const approvalCard = findApprovalCard(adminPage, professor.email);
    await expect(approvalCard).toBeVisible();

    await expectConfirmationAndAccept(
      adminPage,
      () => approvalCard.getByRole('button', { name: 'Aprovar Conta' }).click(),
      'Aprovar a conta docente',
    );

    await expect(findApprovalCard(adminPage, professor.email)).toHaveCount(0);
    await adminPage.getByRole('button', { name: 'Aprovados' }).click();
    const approvedAccountCard = findApprovalCard(adminPage, professor.email);
    await expect(approvedAccountCard).toContainText('Aprovado');

    await adminContext.close();

    const professorApprovedContext = await browser.newContext();
    const professorApprovedPage = await professorApprovedContext.newPage();

    await loginProfessor(professorApprovedPage, professor.email, professor.password);
    await professorApprovedPage.getByRole('link', { name: /Pedidos ao Admin/ }).click();
    await professorApprovedPage.getByRole('button', { name: 'Novo Pedido' }).click();

    const modal = professorApprovedPage.locator('div[role="dialog"], div.fixed.inset-0').last();
    await modal.locator('select').selectOption('operations');
    await modal.getByPlaceholder('Breve descrição').fill(requestTitle);
    await modal.getByPlaceholder('Detalhe do pedido...').fill(requestDescription);
    await expectConfirmationAndAccept(
      professorApprovedPage,
      () => modal.getByRole('button', { name: 'Submeter Pedido' }).click(),
      'Submeter este pedido',
    );

    const pendingCard = findRequestCard(professorApprovedPage, requestTitle);
    await expect(pendingCard).toContainText('Pendente');

    await professorApprovedContext.close();

    const adminRequestsContext = await browser.newContext();
    const adminRequestsPage = await adminRequestsContext.newPage();

    await loginAdmin(adminRequestsPage);

    await adminRequestsPage.getByRole('link', { name: /Pedidos Admin/ }).click();
    const requestCard = findRequestCard(adminRequestsPage, requestTitle);
    await expect(requestCard).toBeVisible();

    await requestCard.getByPlaceholder('Nota administrativa (opcional)').fill(adminDecisionNote);
    await expectConfirmationAndAccept(
      adminRequestsPage,
      () => requestCard.getByRole('button', { name: /Aprovar/ }).click(),
      'Aprovar este pedido administrativo',
    );

    await expect(requestCard).toContainText('Aprovado');
    await expect(requestCard).toContainText(adminDecisionNote);

    await adminRequestsContext.close();

    const professorVerifyContext = await browser.newContext();
    const professorVerifyPage = await professorVerifyContext.newPage();

    await loginProfessor(professorVerifyPage, professor.email, professor.password);
    await professorVerifyPage.getByRole('link', { name: /Pedidos ao Admin/ }).click();

    const approvedCard = findRequestCard(professorVerifyPage, requestTitle);
    await expect(approvedCard).toContainText('Aprovado');
    await expect(approvedCard).toContainText(adminDecisionNote);

    await professorVerifyContext.close();
  });

  test('Admin creates and removes course unit assigning professor tag', async ({ browser }) => {
    const context = await browser.newContext();
    const page = await context.newPage();

    await loginAdmin(page);
    await page.getByRole('link', { name: /Disciplinas/ }).click();

    await page.getByRole('button', { name: 'Criar Disciplina' }).click();
    const modal = page.locator('div.fixed.inset-0 div.relative.bg-surface').first();

    await modal.getByPlaceholder('Ex: 41000').fill(ucCode);
    await modal.getByPlaceholder('Ex: Sistemas Digitais').fill(ucName);
    await modal.getByPlaceholder('Ex: SD').fill(ucAcronym);
    await modal.locator('select').first().selectOption('S2');
    await modal.getByPlaceholder('2025/2026').fill('2025/2026');

    const professorSearch = modal.getByPlaceholder('Procurar docente por nome, email ou NMec...');
    await professorSearch.fill(professor.name.split(' ')[0]);
    await modal.locator('div.cursor-pointer').filter({ hasText: professor.email }).first().click();

    await expect(modal.locator('span').filter({ hasText: professor.name })).toBeVisible();

    await modal.getByRole('button', { name: /^Criar Disciplina$/ }).click();

    const ucRow = page.locator('tr').filter({ hasText: ucName }).first();
    await expect(ucRow).toBeVisible();
    await expect(ucRow).toContainText(professor.name);

    await ucRow.hover();
    await expectConfirmationAndAccept(
      page,
      () => ucRow.locator('button:has(i.pi-trash)').click(),
      'remover esta disciplina',
    );

    await expect(page.locator('tr').filter({ hasText: ucName })).toHaveCount(0);

    await context.close();
  });
});
