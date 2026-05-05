<template>
  <div class="space-y-8">
    <!-- Sem Disciplinas Atribuídas -->
    <div v-if="!authStore.hasCourseUnits" class="space-y-8">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
          Acesso Restrito
        </p>
        <h3 class="text-3xl font-bold">Nenhuma Disciplina Atribuída</h3>
        <p class="text-text-secondary mt-1">
          Ainda não tem unidades curriculares associadas à sua conta.
        </p>
      </div>
      <div class="bg-surface rounded-card border border-white/5 p-8">
        <div class="max-w-lg">
          <div class="flex items-center gap-4 mb-6">
            <div class="w-12 h-12 rounded-full bg-warning/10 flex items-center justify-center">
              <i class="pi pi-exclamation-circle text-warning text-xl"></i>
            </div>
            <div>
              <p class="font-bold">Solicitar Acesso a Disciplinas</p>
              <p class="text-text-secondary text-sm">
                Contacte o administrador da plataforma para atribuir uma ou mais unidades curriculares.
              </p>
            </div>
          </div>
          <router-link
            to="/professor/requests"
            class="inline-flex items-center gap-2 px-6 py-3 bg-brand text-white rounded-btn hover:bg-brand/80 transition-all font-semibold"
          >
            <i class="pi pi-envelope"></i>
            Enviar Pedido ao Admin
          </router-link>
        </div>
      </div>
    </div>

    <!-- Conteúdo Principal -->
    <template v-else>
      <!-- Loading inicial -->
      <div
        v-if="reportedStore.isLoading && !reportedStore.hasLoaded"
        class="flex items-center justify-center py-20"
      >
        <div class="text-center">
          <i class="pi pi-spinner pi-spin text-brand text-4xl mb-4 block"></i>
          <p class="text-text-secondary">A carregar exercícios reportados...</p>
        </div>
      </div>

      <div class="space-y-8" v-else>
        <!-- Cabeçalho -->
        <div class="flex items-start justify-between">
          <div>
            <p class="text-error font-bold text-sm uppercase tracking-widest mb-1">
              Atenção Necessária
            </p>
            <h3 class="text-3xl font-bold">Perguntas Reportadas</h3>
            <p class="text-text-secondary mt-1">
              Exercícios reportados por 3 ou mais alunos diferentes. Reveja e corrija ou dispense o report.
            </p>
          </div>
          <button
            @click="reportedStore.loadReportedExercises(true)"
            :disabled="reportedStore.isLoading"
            class="inline-flex items-center gap-2 px-4 py-2 bg-background border border-white/10 rounded-btn text-sm font-bold hover:border-brand transition-all disabled:opacity-50"
          >
            <i :class="reportedStore.isLoading ? 'pi pi-spinner pi-spin' : 'pi pi-refresh'"></i>
            Atualizar
          </button>
        </div>

        <!-- Erro -->
        <div
          v-if="reportedStore.error"
          class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
        >
          <i class="pi pi-exclamation-triangle mr-2"></i>{{ reportedStore.error }}
        </div>

        <!-- Estatísticas -->
        <div class="grid grid-cols-3 gap-6">
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Total Reportados</p>
            <p class="text-3xl font-bold mt-2 text-error">
              {{ reportedStore.reportedExercises.length }}
            </p>
          </div>
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Mais Reportado</p>
            <p class="text-3xl font-bold mt-2 text-warning">
              {{ maxReportCount }}
              <span class="text-sm font-normal text-text-secondary">reports</span>
            </p>
          </div>
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Disciplinas Afetadas</p>
            <p class="text-3xl font-bold mt-2 text-brand">
              {{ affectedDisciplines }}
            </p>
          </div>
        </div>

        <!-- Filtros -->
        <div class="bg-surface rounded-card border border-white/5 p-6">
          <h4 class="text-sm font-bold text-text-secondary uppercase tracking-widest mb-4">
            Filtros
          </h4>
          <div class="flex flex-wrap items-center gap-4">
            <div class="flex items-center gap-2">
              <span class="text-text-secondary text-xs font-bold uppercase">Disciplina:</span>
              <select
                v-model="disciplineFilter"
                class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand"
              >
                <option value="">Todas</option>
                <option v-for="uc in authStore.user?.course_units || []" :key="uc.id" :value="uc.id">
                  {{ uc.name }}
                </option>
              </select>
            </div>

            <div class="flex items-center gap-2">
              <span class="text-text-secondary text-xs font-bold uppercase">Dificuldade:</span>
              <select
                v-model="difficultyFilter"
                class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand"
              >
                <option value="">Todas</option>
                <option value="Easy">Fácil</option>
                <option value="Medium">Médio</option>
                <option value="Hard">Difícil</option>
              </select>
            </div>

            <div class="flex items-center gap-2">
              <span class="text-text-secondary text-xs font-bold uppercase">Ordenar por:</span>
              <select
                v-model="sortBy"
                class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand"
              >
                <option value="report_count">Nº de Reports</option>
                <option value="last_reported_at">Mais Recente</option>
              </select>
            </div>

            <button
              v-if="hasActiveFilters"
              @click="clearFilters"
              class="text-error text-xs font-bold hover:text-error/80 ml-auto"
            >
              <i class="pi pi-filter-slash mr-1"></i> Limpar Filtros
            </button>
          </div>
          <p class="text-text-secondary text-xs mt-3">
            {{ filteredExercises.length }} exercício(s) encontrado(s)
          </p>
        </div>

        <!-- Estado vazio -->
        <div
          v-if="filteredExercises.length === 0 && !reportedStore.isLoading"
          class="bg-surface rounded-card border border-white/5 p-16 text-center"
        >
          <div class="w-16 h-16 rounded-full bg-success/10 flex items-center justify-center mx-auto mb-4">
            <i class="pi pi-check-circle text-success text-3xl"></i>
          </div>
          <p class="font-bold text-lg">Nenhuma pergunta reportada</p>
          <p class="text-text-secondary text-sm mt-1">
            Não existem exercícios com 3 ou mais reports de alunos diferentes.
          </p>
        </div>

        <!-- Tabela -->
        <div
          v-else
          class="bg-surface rounded-card border border-white/5 overflow-x-auto relative"
        >
          <div
            v-if="reportedStore.isLoading"
            class="absolute inset-0 bg-black/40 backdrop-blur-sm z-20 flex items-center justify-center"
          >
            <i class="pi pi-spinner pi-spin text-brand text-3xl"></i>
          </div>

          <table class="w-full text-left min-w-[900px]">
            <thead class="bg-black/20 text-text-secondary uppercase text-[10px] tracking-widest">
              <tr>
                <th class="px-6 py-4 font-semibold w-10">#</th>
                <th class="px-6 py-4 font-semibold">Exercício</th>
                <th class="px-6 py-4 font-semibold text-center">Tipo</th>
                <th class="px-6 py-4 font-semibold text-center">Disciplina</th>
                <th class="px-6 py-4 font-semibold text-center">Tópico</th>
                <th class="px-6 py-4 font-semibold text-center">Dificuldade</th>
                <th class="px-6 py-4 font-semibold text-center">Reports</th>
                <th class="px-6 py-4 font-semibold text-center">Último Report</th>
                <th class="px-6 py-4 font-semibold text-right">Ações</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
              <tr
                v-for="(ex, idx) in paginatedExercises"
                :key="ex.id_exercise"
                class="hover:bg-white/[0.02] transition-colors group"
              >
                <td class="px-6 py-4 text-text-secondary text-xs">
                  {{ (currentPage - 1) * pageSize + idx + 1 }}
                </td>
                <td class="px-6 py-4 max-w-[260px]">
                  <p class="font-medium text-sm truncate" :title="ex.question">
                    {{ ex.question }}
                  </p>
                </td>
                <td class="px-6 py-4 text-center whitespace-nowrap">
                  <span
                    class="text-xs font-bold px-3 py-1 rounded-chip"
                    :class="typeClass(ex.type)"
                  >
                    {{ typeLabel(ex.type) }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center max-w-[140px]">
                  <span
                    class="bg-brand/10 text-brand text-xs font-bold px-3 py-1 rounded-chip truncate block"
                    :title="ex.discipline"
                  >
                    {{ ex.discipline || `UC ${ex.id_uc}` }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center max-w-[160px]">
                  <span class="text-text-secondary text-xs truncate block" :title="ex.topic_name">
                    {{ ex.topic_name || '—' }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center whitespace-nowrap">
                  <span
                    class="text-xs font-bold px-3 py-1 rounded-chip"
                    :class="
                      ex.difficulty === 'Easy'
                        ? 'bg-success/10 text-success'
                        : ex.difficulty === 'Medium'
                          ? 'bg-warning/10 text-warning'
                          : 'bg-error/10 text-error'
                    "
                  >
                    {{ difficultyLabel[ex.difficulty] || ex.difficulty }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center">
                  <span
                    class="inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1 rounded-chip"
                    :class="ex.report_count >= 5 ? 'bg-error/20 text-error' : 'bg-warning/20 text-warning'"
                  >
                    <i class="pi pi-flag-fill text-[10px]"></i>
                    {{ ex.report_count }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center text-text-secondary text-xs whitespace-nowrap">
                  {{ formatDate(ex.last_reported_at) }}
                </td>
                <td class="px-6 py-4 text-right">
                  <div
                    class="flex justify-end gap-3 opacity-0 group-hover:opacity-100 transition-opacity"
                    :class="{ 'pointer-events-none': reportedStore.isLoading }"
                  >
                    <button
                      @click="showDetail(ex)"
                      class="text-text-secondary hover:text-brand"
                      title="Ver detalhe"
                    >
                      <i class="pi pi-eye"></i>
                    </button>
                    <button
                      @click="openEdit(ex)"
                      class="text-text-secondary hover:text-brand"
                      title="Editar exercício"
                    >
                      <i class="pi pi-pencil"></i>
                    </button>
                    <button
                      @click="confirmDismiss(ex)"
                      class="text-text-secondary hover:text-success"
                      title="Dispensar report"
                    >
                      <i class="pi pi-check"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>

          <!-- Paginação -->
          <div
            v-if="totalPages > 1"
            class="flex items-center justify-between px-6 py-4 border-t border-white/5"
          >
            <p class="text-text-secondary text-xs">
              Página {{ currentPage }} de {{ totalPages }}
            </p>
            <div class="flex gap-2">
              <button
                @click="currentPage--"
                :disabled="currentPage === 1"
                class="px-3 py-1.5 rounded-btn text-xs font-bold bg-background border border-white/10 disabled:opacity-30 hover:border-brand transition-all"
              >
                Anterior
              </button>
              <button
                @click="currentPage++"
                :disabled="currentPage === totalPages"
                class="px-3 py-1.5 rounded-btn text-xs font-bold bg-background border border-white/10 disabled:opacity-30 hover:border-brand transition-all"
              >
                Seguinte
              </button>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>

  <!-- ─── Modal de Detalhe ──────────────────────────────────────────────────── -->
  <Teleport to="body">
    <div v-if="detailExercise" class="fixed inset-0 z-50 flex items-center justify-center">
      <div
        class="absolute inset-0 bg-black/60 backdrop-blur-sm"
        @click="detailExercise = null"
      ></div>
      <div
        class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-8 shadow-2xl z-10 max-h-[90vh] overflow-y-auto"
      >
        <div class="flex justify-between items-center mb-6">
          <div class="flex items-center gap-2 flex-wrap">
            <span class="bg-brand/10 text-brand text-xs font-bold px-3 py-1 rounded-chip">
              {{ detailExercise.discipline || `UC ${detailExercise.id_uc}` }}
            </span>
            <span
              class="text-xs font-bold px-3 py-1 rounded-chip"
              :class="typeClass(detailExercise.type)"
            >
              {{ typeLabel(detailExercise.type) }}
            </span>
            <span
              class="inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1 rounded-chip"
              :class="detailExercise.report_count >= 5 ? 'bg-error/20 text-error' : 'bg-warning/20 text-warning'"
            >
              <i class="pi pi-flag-fill text-[10px]"></i>
              {{ detailExercise.report_count }} reports
            </span>
          </div>
          <button
            @click="detailExercise = null"
            class="text-text-secondary hover:text-white transition-colors"
          >
            <i class="pi pi-times"></i>
          </button>
        </div>

        <h4 class="font-bold text-lg mb-6 leading-relaxed">
          {{ detailExercise.question }}
        </h4>

        <!-- Opções (Multiple Choice) -->
        <div v-if="detailExercise.type === 'Multiple Choice'" class="space-y-2 mb-6">
          <div
            v-for="(opt, i) in (detailExercise.solution?.options || [])"
            :key="i"
            class="flex items-center gap-3 p-3 rounded-btn border"
            :class="
              isCorrectOption(detailExercise, i)
                ? 'border-success/30 bg-success/10'
                : 'border-white/5 bg-background'
            "
          >
            <span
              class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0"
              :class="
                isCorrectOption(detailExercise, i)
                  ? 'bg-success text-white'
                  : 'bg-white/10 text-text-secondary'
              "
            >
              {{ String.fromCharCode(65 + i) }}
            </span>
            <span class="text-sm">{{ opt }}</span>
            <i v-if="isCorrectOption(detailExercise, i)" class="pi pi-check text-success ml-auto text-xs"></i>
          </div>
        </div>

        <!-- Opções (True/False) -->
        <div v-else-if="detailExercise.type === 'True/False'" class="flex gap-3 mb-6">
          <div
            v-for="label in ['Verdadeiro', 'Falso']"
            :key="label"
            class="flex-1 p-3 rounded-btn border text-center text-sm font-bold"
            :class="
              isTrueFalseCorrect(detailExercise, label)
                ? 'border-success/30 bg-success/10 text-success'
                : 'border-white/5 bg-background text-text-secondary'
            "
          >
            <i
              :class="
                label === 'Verdadeiro'
                  ? 'pi pi-check mr-2'
                  : 'pi pi-times mr-2'
              "
            ></i>{{ label }}
          </div>
        </div>

        <!-- Explicação -->
        <div v-if="detailExercise.explanation" class="bg-background rounded-btn p-4 mb-6">
          <p class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2">Explicação</p>
          <p class="text-sm text-text-secondary leading-relaxed">{{ detailExercise.explanation }}</p>
        </div>

        <!-- Info de reports -->
        <div class="bg-error/5 border border-error/20 rounded-btn p-4 mb-6">
          <p class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2">
            Informação de Reports
          </p>
          <div class="flex gap-6 text-sm">
            <div>
              <p class="text-text-secondary text-xs">Primeiro report</p>
              <p class="font-bold">{{ formatDate(detailExercise.first_reported_at) }}</p>
            </div>
            <div>
              <p class="text-text-secondary text-xs">Último report</p>
              <p class="font-bold">{{ formatDate(detailExercise.last_reported_at) }}</p>
            </div>
            <div>
              <p class="text-text-secondary text-xs">Total de reports</p>
              <p class="font-bold text-error">{{ detailExercise.report_count }}</p>
            </div>
          </div>
        </div>

        <div class="flex gap-3">
          <button
            @click="openEdit(detailExercise); detailExercise = null"
            class="flex-1 inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-brand text-white rounded-btn hover:bg-brand/80 transition-all text-sm font-semibold"
          >
            <i class="pi pi-pencil"></i> Editar Exercício
          </button>
          <button
            @click="confirmDismiss(detailExercise); detailExercise = null"
            class="flex-1 inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-success/10 border border-success/30 text-success rounded-btn hover:bg-success/20 transition-all text-sm font-semibold"
          >
            <i class="pi pi-check"></i> Dispensar Report
          </button>
        </div>
      </div>
    </div>
  </Teleport>

  <!-- ─── Modal de Edição ───────────────────────────────────────────────────── -->
  <Teleport to="body">
    <div v-if="editExercise" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="closeEdit"></div>
      <div
        class="relative bg-surface border border-white/10 rounded-card w-full max-w-2xl shadow-2xl z-10 max-h-[90vh] flex flex-col"
      >
        <div class="flex justify-between items-center px-8 py-5 border-b border-white/5">
          <div>
            <h4 class="font-bold text-lg">Editar Exercício Reportado</h4>
            <p class="text-text-secondary text-xs mt-0.5">
              Tópico: {{ editExercise.topic_name }} · {{ editExercise.discipline || `UC ${editExercise.id_uc}` }}
            </p>
          </div>
          <button @click="closeEdit" class="text-text-secondary hover:text-white transition-colors">
            <i class="pi pi-times"></i>
          </button>
        </div>

        <div class="overflow-y-auto p-8 space-y-6">
          <!-- Pergunta -->
          <div>
            <label class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2">
              Pergunta
            </label>
            <textarea
              v-model="editForm.question"
              rows="3"
              class="w-full bg-background border border-white/10 rounded-btn px-4 py-3 text-sm outline-none focus:border-brand resize-none transition-colors"
              placeholder="Escreve a pergunta..."
            ></textarea>
          </div>

          <!-- Tipo e Dificuldade -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2">Tipo</label>
              <select
                v-model="editForm.type"
                class="w-full bg-background border border-white/10 rounded-btn px-4 py-3 text-sm outline-none focus:border-brand"
              >
                <option value="Multiple Choice">Escolha Múltipla</option>
                <option value="True/False">Verdadeiro/Falso</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2">Dificuldade</label>
              <select
                v-model="editForm.difficulty"
                class="w-full bg-background border border-white/10 rounded-btn px-4 py-3 text-sm outline-none focus:border-brand"
              >
                <option value="Easy">Fácil</option>
                <option value="Medium">Médio</option>
                <option value="Hard">Difícil</option>
              </select>
            </div>
          </div>

          <!-- Opções (Multiple Choice) -->
          <div v-if="editForm.type === 'Multiple Choice'">
            <label class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-3">
              Opções <span class="text-brand ml-1">— clica no círculo para marcar a correta</span>
            </label>
            <div class="space-y-2">
              <div
                v-for="(opt, i) in editForm.options"
                :key="i"
                class="flex items-center gap-3"
              >
                <button
                  type="button"
                  @click="editForm.correct = i"
                  class="w-7 h-7 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-all"
                  :class="
                    editForm.correct === i
                      ? 'border-success bg-success text-white'
                      : 'border-white/20 hover:border-white/50'
                  "
                >
                  <i v-if="editForm.correct === i" class="pi pi-check text-[10px]"></i>
                  <span v-else class="text-xs font-bold text-text-secondary">{{ String.fromCharCode(65 + i) }}</span>
                </button>
                <input
                  v-model="editForm.options[i]"
                  type="text"
                  class="flex-1 bg-background border rounded-btn px-4 py-2.5 text-sm outline-none focus:border-brand transition-colors"
                  :class="
                    editForm.correct === i
                      ? 'border-success/30 focus:border-success'
                      : 'border-white/10'
                  "
                  :placeholder="`Opção ${String.fromCharCode(65 + i)}`"
                />
                <button
                  v-if="editForm.options.length > 2"
                  type="button"
                  @click="removeOption(i)"
                  class="text-text-secondary hover:text-error transition-colors"
                >
                  <i class="pi pi-times text-xs"></i>
                </button>
              </div>
            </div>
            <button
              v-if="editForm.options.length < 6"
              type="button"
              @click="addOption"
              class="mt-3 text-xs text-brand font-bold hover:text-brand/70 transition-colors"
            >
              <i class="pi pi-plus mr-1"></i> Adicionar opção
            </button>
          </div>

          <!-- Opções (True/False) -->
          <div v-else-if="editForm.type === 'True/False'">
            <label class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-3">
              Resposta Correta
            </label>
            <div class="flex gap-3">
              <button
                type="button"
                @click="editForm.correct = 'True'"
                class="flex-1 py-3 rounded-btn border text-sm font-bold transition-all"
                :class="
                  editForm.correct === 'True'
                    ? 'border-success/40 bg-success/10 text-success'
                    : 'border-white/10 bg-background text-text-secondary hover:border-white/30'
                "
              >
                <i class="pi pi-check mr-2"></i>Verdadeiro
              </button>
              <button
                type="button"
                @click="editForm.correct = 'False'"
                class="flex-1 py-3 rounded-btn border text-sm font-bold transition-all"
                :class="
                  editForm.correct === 'False'
                    ? 'border-error/40 bg-error/10 text-error'
                    : 'border-white/10 bg-background text-text-secondary hover:border-white/30'
                "
              >
                <i class="pi pi-times mr-2"></i>Falso
              </button>
            </div>
          </div>

          <!-- Explicação -->
          <div>
            <label class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2">
              Explicação
              <span class="text-text-secondary font-normal normal-case ml-1">(opcional)</span>
            </label>
            <textarea
              v-model="editForm.explanation"
              rows="3"
              class="w-full bg-background border border-white/10 rounded-btn px-4 py-3 text-sm outline-none focus:border-brand resize-none transition-colors"
              placeholder="Explica a resposta correta..."
            ></textarea>
          </div>

          <!-- Erro -->
          <div
            v-if="editError"
            class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-btn text-sm"
          >
            <i class="pi pi-exclamation-triangle mr-2"></i>{{ editError }}
          </div>
        </div>

        <div class="flex justify-end gap-3 px-8 py-5 border-t border-white/5">
          <button
            @click="closeEdit"
            class="px-5 py-2.5 rounded-btn text-sm font-bold bg-background border border-white/10 hover:border-white/30 transition-all"
          >
            Cancelar
          </button>
          <button
            @click="saveEdit"
            :disabled="isSaving"
            class="inline-flex items-center gap-2 px-6 py-2.5 bg-brand text-white rounded-btn hover:bg-brand/80 transition-all text-sm font-semibold disabled:opacity-50"
          >
            <i :class="isSaving ? 'pi pi-spinner pi-spin' : 'pi pi-check'"></i>
            {{ isSaving ? 'A guardar...' : 'Guardar Alterações' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>

  <!-- ─── Modal de Confirmação Dispensar ───────────────────────────────────── -->
  <Teleport to="body">
    <div v-if="dismissTarget" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="dismissTarget = null"></div>
      <div class="relative bg-surface border border-white/10 rounded-card w-full max-w-md p-8 shadow-2xl z-10">
        <div class="flex items-center gap-4 mb-4">
          <div class="w-12 h-12 rounded-full bg-success/10 flex items-center justify-center flex-shrink-0">
            <i class="pi pi-check-circle text-success text-xl"></i>
          </div>
          <div>
            <p class="font-bold">Dispensar report?</p>
            <p class="text-text-secondary text-sm mt-0.5">
              Os {{ dismissTarget.report_count }} reports serão apagados. O exercício continua publicado.
            </p>
          </div>
        </div>
        <p class="text-sm text-text-secondary bg-background rounded-btn p-3 mb-6 truncate" :title="dismissTarget.question">
          "{{ dismissTarget.question }}"
        </p>
        <div class="flex gap-3">
          <button
            @click="dismissTarget = null"
            class="flex-1 px-4 py-2.5 rounded-btn text-sm font-bold bg-background border border-white/10 hover:border-white/30 transition-all"
          >
            Cancelar
          </button>
          <button
            @click="executeDismiss"
            :disabled="reportedStore.isLoading"
            class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-success text-white rounded-btn hover:bg-success/80 transition-all text-sm font-semibold disabled:opacity-50"
          >
            <i :class="reportedStore.isLoading ? 'pi pi-spinner pi-spin' : 'pi pi-check'"></i>
            Confirmar
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { useReportedExerciseStore } from '../stores/reportedExerciseStore';
import { useExerciseStore } from '../stores/exerciseStore';

const authStore = useAuthStore();
const reportedStore = useReportedExerciseStore();
const exerciseStore = useExerciseStore();

onMounted(async () => {
  await reportedStore.loadReportedExercises();
});

// ─── Filtros e ordenação ───────────────────────────────────────────────────

const disciplineFilter = ref('');
const difficultyFilter = ref('');
const sortBy = ref('report_count');
const currentPage = ref(1);
const pageSize = 15;

const difficultyLabel = { Easy: 'Fácil', Medium: 'Médio', Hard: 'Difícil' };

const hasActiveFilters = computed(
  () => !!disciplineFilter.value || !!difficultyFilter.value,
);

function clearFilters() {
  disciplineFilter.value = '';
  difficultyFilter.value = '';
  currentPage.value = 1;
}

watch([disciplineFilter, difficultyFilter, sortBy], () => {
  currentPage.value = 1;
});

// ─── Exercícios filtrados ──────────────────────────────────────────────────

const filteredExercises = computed(() => {
  let list = [...reportedStore.reportedExercises];

  // Filtra apenas pelas UCs do professor
  const userIds = authStore.user?.course_units?.map((uc) => uc.id) || [];
  if (userIds.length > 0) list = list.filter((e) => userIds.includes(e.id_uc));

  if (disciplineFilter.value)
    list = list.filter((e) => e.id_uc === Number(disciplineFilter.value));

  if (difficultyFilter.value)
    list = list.filter((e) => e.difficulty === difficultyFilter.value);

  // Ordenação
  list.sort((a, b) => {
    if (sortBy.value === 'report_count') return b.report_count - a.report_count;
    return new Date(b.last_reported_at).getTime() - new Date(a.last_reported_at).getTime();
  });

  return list;
});

const totalPages = computed(() =>
  Math.max(1, Math.ceil(filteredExercises.value.length / pageSize)),
);
const paginatedExercises = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  return filteredExercises.value.slice(start, start + pageSize);
});

// ─── Estatísticas ──────────────────────────────────────────────────────────

const maxReportCount = computed(() => {
  if (!reportedStore.reportedExercises.length) return 0;
  return Math.max(...reportedStore.reportedExercises.map((e) => e.report_count));
});

const affectedDisciplines = computed(() => {
  const ids = new Set(reportedStore.reportedExercises.map((e) => e.id_uc));
  return ids.size;
});

// ─── Modal de Detalhe ─────────────────────────────────────────────────────

const detailExercise = ref(null);
function showDetail(ex) {
  detailExercise.value = ex;
}

// ─── Modal de Edição ──────────────────────────────────────────────────────

const editExercise = ref(null);
const isSaving = ref(false);
const editError = ref(null);

const editForm = ref({
  question: '',
  type: 'Multiple Choice',
  difficulty: 'Easy',
  options: ['', '', '', ''],
  correct: 0,
  explanation: '',
});

function openEdit(ex) {
  editExercise.value = ex;
  editError.value = null;
  let correct;
  if (ex.type === 'Multiple Choice') {
    const c = ex.solution?.correct ?? ex.correct;
    if (typeof c === 'number') correct = c;
    else if (typeof c === 'string' && /^[A-Da-d]$/.test(c))
      correct = c.toUpperCase().charCodeAt(0) - 65;
    else if (typeof c === 'string' && !isNaN(Number(c))) correct = Number(c);
    else correct = 0;
  } else {
    const c = ex.solution?.correct ?? ex.correct;
    const cStr = String(c ?? '').toLowerCase();
    correct = cStr === 'true' || cStr === 'verdadeiro' ? 'True' : 'False';
  }
  editForm.value = {
    question: ex.question || '',
    type: ex.type || 'Multiple Choice',
    difficulty: ex.difficulty || 'Easy',
    options: ex.solution?.options?.length ? [...ex.solution.options] : ['', '', '', ''],
    correct,
    explanation: ex.explanation || '',
  };
}

function closeEdit() {
  editExercise.value = null;
  editError.value = null;
}

function addOption() {
  if (editForm.value.options.length < 6) editForm.value.options.push('');
}

function removeOption(i) {
  if (editForm.value.options.length <= 2) return;
  editForm.value.options.splice(i, 1);
  if (typeof editForm.value.correct === 'number') {
    if (editForm.value.correct === i) editForm.value.correct = 0;
    else if (editForm.value.correct > i) editForm.value.correct--;
  }
}

async function saveEdit() {
  editError.value = null;
  if (!editForm.value.question.trim()) {
    editError.value = 'A pergunta não pode estar vazia.';
    return;
  }
  if (
    editForm.value.type === 'Multiple Choice' &&
    editForm.value.options.some((o) => !o.trim())
  ) {
    editError.value = 'Todas as opções têm de estar preenchidas.';
    return;
  }
  isSaving.value = true;
  try {
    const rawCorrect = editForm.value.correct;
    const correctLetter =
      editForm.value.type === 'Multiple Choice'
        ? typeof rawCorrect === 'number'
          ? String.fromCharCode(65 + rawCorrect)
          : String(rawCorrect ?? 'A').toUpperCase()
        : rawCorrect;
    const solution =
      editForm.value.type === 'Multiple Choice'
        ? { options: editForm.value.options, correct: correctLetter }
        : { correct: correctLetter };

    await exerciseStore.updateExercise(editExercise.value.id_exercise, {
      question: editForm.value.question,
      type: editForm.value.type,
      difficulty: editForm.value.difficulty,
      solution,
      explanation: editForm.value.explanation,
    });

    // Atualiza localmente o exercício na lista de reportados
    const idx = reportedStore.reportedExercises.findIndex(
      (e) => e.id_exercise === editExercise.value.id_exercise,
    );
    if (idx !== -1) {
      reportedStore.reportedExercises[idx] = {
        ...reportedStore.reportedExercises[idx],
        question: editForm.value.question,
        type: editForm.value.type,
        difficulty: editForm.value.difficulty,
        solution,
        explanation: editForm.value.explanation,
      };
    }
    closeEdit();
  } catch {
    editError.value = 'Erro ao guardar. Tenta novamente.';
  } finally {
    isSaving.value = false;
  }
}

// ─── Dispensar Report ──────────────────────────────────────────────────────

const dismissTarget = ref(null);

function confirmDismiss(ex) {
  dismissTarget.value = ex;
}

async function executeDismiss() {
  if (!dismissTarget.value) return;
  try {
    await reportedStore.dismissReport(dismissTarget.value.id_exercise);
    dismissTarget.value = null;
  } catch {
    // erro já tratado na store
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

const typeLabel = (type) =>
  ({ 'Multiple Choice': 'Escolha Múltipla', 'True/False': 'V/F' })[type] || type || 'Escolha Múltipla';

const typeClass = (type) =>
  ({ 'Multiple Choice': 'bg-brand/10 text-brand', 'True/False': 'bg-purple-500/10 text-purple-400' })[type] ||
  'bg-brand/10 text-brand';

function isCorrectOption(ex, index) {
  const c = ex.solution?.correct ?? ex.correct;
  if (c === null || c === undefined) return false;
  if (typeof c === 'number') return c === index;
  if (typeof c === 'string') {
    if (/^[A-Da-d]$/.test(c)) return c.toUpperCase().charCodeAt(0) - 65 === index;
    if (!isNaN(Number(c))) return Number(c) === index;
  }
  return false;
}

function isTrueFalseCorrect(ex, label) {
  const c = ex.solution?.correct ?? ex.correct;
  if (c === null || c === undefined) return false;
  const cStr = String(c).toLowerCase();
  const isTrue = cStr === 'true' || cStr === 'verdadeiro';
  return label === 'Verdadeiro' ? isTrue : !isTrue;
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  return new Date(dateStr).toLocaleDateString('pt-PT', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}
</script>
