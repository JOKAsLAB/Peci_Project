-- =============================================================
-- TESTE DE INTEGRIDADE ADMIN/PROFESSOR (TRANSACIONAL)
-- Objetivo: validar relações e transição de estado sem poluir dados.
-- =============================================================

BEGIN;

INSERT INTO base_user ("ID_User", "Name", "Email", "Password_Hash", "Role", "Status")
VALUES
  ('10000000-0000-0000-0000-000000000001', 'Admin Integridade', 'admin.integridade@ua.pt', 'hash_admin', 'ADMIN', 'ACTIVE'),
  ('10000000-0000-0000-0000-000000000002', 'Professor A', 'prof.a.integridade@ua.pt', 'hash_prof_a', 'PROFESSOR', 'ACTIVE'),
  ('10000000-0000-0000-0000-000000000003', 'Professor B', 'prof.b.integridade@ua.pt', 'hash_prof_b', 'PROFESSOR', 'ACTIVE');

INSERT INTO admin ("ID_Admin", "Privilege_Level", "Contact")
VALUES ('10000000-0000-0000-0000-000000000001', 3, 'admin.integridade@ua.pt');

INSERT INTO professor ("ID_Professor", "Department", "Office", "Short_Bio")
VALUES
  ('10000000-0000-0000-0000-000000000002', 'DETI', '2.21', 'Professor A para teste de integridade'),
  ('10000000-0000-0000-0000-000000000003', 'DETI', '2.22', 'Professor B para teste de integridade');

INSERT INTO course_unit ("ID_UC", "Name", "Semester", "Curricular_Year")
VALUES (91001, 'UC Integridade Admin/Professor', '2S', 3);

INSERT INTO professor_uc ("ID_Professor", "ID_UC")
VALUES ('10000000-0000-0000-0000-000000000002', 91001);

INSERT INTO request ("ID_Professor", "ID_Admin", "Request_Type", "Title", "Description", "Status")
VALUES
  ('10000000-0000-0000-0000-000000000002', NULL, 'ACCESS', '[access] Pedido de acesso ao painel', 'Fluxo inicial pendente', 'PENDING'),
  ('10000000-0000-0000-0000-000000000003', NULL, 'PLATFORM', '[platform] Erro de plataforma', 'Fluxo inicial pendente', 'PENDING');

DO $$
DECLARE
  pending_count INTEGER;
  assignment_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO pending_count
  FROM request
  WHERE "Status" = 'PENDING'
    AND "ID_Professor" IN (
      '10000000-0000-0000-0000-000000000002',
      '10000000-0000-0000-0000-000000000003'
    );

  IF pending_count <> 2 THEN
    RAISE EXCEPTION 'Esperado 2 pedidos pendentes, obtido %', pending_count;
  END IF;

  SELECT COUNT(*) INTO assignment_count
  FROM professor_uc
  WHERE "ID_Professor" = '10000000-0000-0000-0000-000000000002'
    AND "ID_UC" = 91001;

  IF assignment_count <> 1 THEN
    RAISE EXCEPTION 'Mapeamento Professor_UC em falta para professor A.';
  END IF;
END $$;

UPDATE request
SET
  "Status" = 'APPROVED',
  "ID_Admin" = '10000000-0000-0000-0000-000000000001',
  "AdminComment" = 'Aprovado no teste transacional',
  "Resolution_Date" = NOW()
WHERE "ID_Professor" = '10000000-0000-0000-0000-000000000002'
  AND "Status" = 'PENDING';

DO $$
DECLARE
  approved_count INTEGER;
  unresolved_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO approved_count
  FROM request
  WHERE "ID_Professor" = '10000000-0000-0000-0000-000000000002'
    AND "Status" = 'APPROVED'
    AND "ID_Admin" = '10000000-0000-0000-0000-000000000001'
    AND "Resolution_Date" IS NOT NULL;

  IF approved_count <> 1 THEN
    RAISE EXCEPTION 'Transição para approved inválida para professor A.';
  END IF;

  SELECT COUNT(*) INTO unresolved_count
  FROM request
  WHERE "ID_Professor" = '10000000-0000-0000-0000-000000000003'
    AND "Status" = 'PENDING'
    AND "ID_Admin" IS NULL;

  IF unresolved_count <> 1 THEN
    RAISE EXCEPTION 'Pedido de professor B devia manter-se pendente e sem admin.';
  END IF;
END $$;

INSERT INTO admin_audit_log ("ID_Admin", "Action", "Target_ID", "Target_Type")
VALUES
  (
    '10000000-0000-0000-0000-000000000001',
    'DECIDE_REQUEST',
    (
      SELECT "ID_Request"::text
      FROM request
      WHERE "ID_Professor" = '10000000-0000-0000-0000-000000000002'
      LIMIT 1
    ),
    'Request'
  );

DO $$
DECLARE
  audit_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO audit_count
  FROM admin_audit_log
  WHERE "ID_Admin" = '10000000-0000-0000-0000-000000000001'
    AND "Action" = 'DECIDE_REQUEST'
    AND "Target_Type" = 'Request';

  IF audit_count <> 1 THEN
    RAISE EXCEPTION 'Audit log de decisão administrativa não foi registado.';
  END IF;
END $$;

ROLLBACK;

-- Se chegou aqui sem exceções, o teste passou.
SELECT 'test_admin_professor_integrity.sql OK' AS result;
