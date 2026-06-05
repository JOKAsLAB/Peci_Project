<template>
  <div class="space-y-8">
    <!-- Sem Disciplinas Atribuídas -->
    <div v-if="!authStore.hasCourseUnits" class="space-y-8">
      <div>
        <h3 class="text-3xl font-bold">Nenhuma Disciplina Atribuída</h3>
        <p class="text-text-secondary mt-1">
          Ainda não tem unidades curriculares associadas à sua conta para editar
          conteúdo.
        </p>
      </div>
      <div class="bg-surface rounded-card border border-white/5 p-8">
        <div class="max-w-lg">
          <div class="flex items-center gap-4 mb-6">
            <div
              class="w-12 h-12 rounded-full bg-warning/10 flex items-center justify-center"
            >
              <i class="pi pi-exclamation-circle text-warning text-xl"></i>
            </div>
            <div>
              <p class="font-bold">Solicitar Acesso a Disciplinas</p>
              <p class="text-text-secondary text-sm">
                Contacte o administrador da plataforma para atribuir uma ou mais
                unidades curriculares.
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
      <div
        v-if="exerciseStore.isLoading && !exerciseStore.hasLoaded"
        class="flex items-center justify-center py-20"
      >
        <div class="text-center">
          <i class="pi pi-spinner pi-spin text-brand text-4xl mb-4 block"></i>
          <p class="text-text-secondary">A carregar exercícios...</p>
        </div>
      </div>

      <div class="space-y-8" v-else>
        <div>
          <h3 class="text-2xl sm:text-3xl font-bold">Banco de Perguntas</h3>
          <p class="text-text-secondary mt-1">
            Consulte, filtre e edite todo o banco de questões.
          </p>
        </div>

        <div
          v-if="exerciseStore.error"
          class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
        >
          <i class="pi pi-exclamation-triangle mr-2"></i
          >{{ exerciseStore.error }}
        </div>

        <!-- Estatísticas -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-6">
          <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-xs sm:text-sm">Total Exercícios</p>
            <p class="text-2xl sm:text-3xl font-bold mt-2">
              {{ filteredExercises.length }}
            </p>
          </div>
          <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-xs sm:text-sm">Publicados</p>
            <p class="text-2xl sm:text-3xl font-bold mt-2 text-success">
              {{ filteredExercises.filter((e) => e.published).length }}
            </p>
          </div>
          <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-xs sm:text-sm">Rascunhos</p>
            <p class="text-2xl sm:text-3xl font-bold mt-2 text-warning">
              {{ filteredExercises.filter((e) => !e.published).length }}
            </p>
          </div>
          <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-xs sm:text-sm">Disciplinas</p>
            <p class="text-2xl sm:text-3xl font-bold mt-2 text-brand">
              {{ authStore.user?.course_units?.length || 0 }}
            </p>
          </div>
        </div>

        <!-- Filtros -->
        <div class="bg-surface rounded-card border border-white/5 p-4 sm:p-6">
          <div class="flex items-center justify-between mb-4">
            <h4 class="text-sm font-bold text-text-secondary uppercase tracking-widest">Filtros</h4>
            <button v-if="hasActiveFilters" @click="clearFilters" class="text-error text-xs font-bold hover:text-error/80">
              <i class="pi pi-filter-slash mr-1"></i> Limpar
            </button>
          </div>
          <!-- Status chips -->
          <div class="flex items-center gap-2 flex-wrap mb-3">
            <button
              v-for="f in ['Todos', 'Publicados', 'Rascunhos']"
              :key="f"
              @click="statusFilter = f"
              :class="statusFilter === f ? 'bg-brand text-white' : 'bg-background text-text-secondary border border-white/10'"
              class="px-4 py-2 rounded-chip text-xs font-bold transition-all"
            >{{ f }}</button>
          </div>
          <!-- Selects — 2 colunas em mobile, linha em desktop -->
          <div class="grid grid-cols-2 sm:flex sm:flex-wrap gap-2 sm:gap-3 sm:items-center">
            <div class="flex flex-col gap-1">
              <span class="text-text-secondary text-[10px] font-bold uppercase">Disciplina</span>
              <select v-model="disciplineFilter" class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand w-full">
                <option value="">Todas</option>
                <option v-for="uc in authStore.user?.course_units || []" :key="uc.id" :value="uc.id">{{ uc.name }}</option>
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <span class="text-text-secondary text-[10px] font-bold uppercase">Tópico</span>
              <select v-model="topicFilter" class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand w-full sm:min-w-[160px]">
                <option value="">Todos</option>
                <option v-for="t in availableTopics" :key="t" :value="t">{{ t }}</option>
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <span class="text-text-secondary text-[10px] font-bold uppercase">Dificuldade</span>
              <select v-model="difficultyFilter" class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand w-full">
                <option value="">Todas</option>
                <option value="Easy">Fácil</option>
                <option value="Medium">Médio</option>
                <option value="Hard">Difícil</option>
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <span class="text-text-secondary text-[10px] font-bold uppercase">Tipo</span>
              <select v-model="typeFilter" class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand w-full">
                <option value="">Todos</option>
                <option value="Multiple Choice">Escolha Múltipla</option>
                <option value="True/False">V/F</option>
              </select>
            </div>
          </div>
          <p class="text-text-secondary text-xs mt-3">{{ filteredExercises.length }} exercício(s) encontrado(s)</p>
        </div>

        <!-- Cards mobile -->
        <div class="sm:hidden space-y-3">
          <div
            v-for="(ex, idx) in paginatedExercises"
            :key="ex.id"
            class="bg-surface rounded-card border border-white/5 p-4"
          >
            <div class="flex items-start justify-between gap-2 mb-2">
              <p class="font-medium text-sm leading-snug flex-1 min-w-0">{{ ex.title }}</p>
              <div class="flex gap-1.5 shrink-0">
                <button @click="showDetail(ex)" title="Ver" class="w-8 h-8 flex items-center justify-center rounded-btn border border-white/10 text-text-secondary hover:text-brand hover:border-brand/50 transition-all"><i class="pi pi-eye text-xs"></i></button>
                <button @click="openEdit(ex)" title="Editar" class="w-8 h-8 flex items-center justify-center rounded-btn border border-white/10 text-text-secondary hover:text-white hover:border-brand/50 transition-all"><i class="pi pi-pencil text-xs"></i></button>
                <button @click="removeExercise(ex.id)" title="Eliminar" class="w-8 h-8 flex items-center justify-center rounded-btn border border-white/10 text-text-secondary hover:text-error hover:border-error/50 transition-all"><i class="pi pi-trash text-xs"></i></button>
              </div>
            </div>
            <div class="flex flex-wrap gap-1.5 items-center">
              <span class="text-xs font-bold px-2 py-0.5 rounded-chip" :class="typeClass(ex.type)">{{ typeLabel(ex.type) }}</span>
              <span class="text-xs font-bold px-2 py-0.5 rounded-chip" :class="ex.difficulty === 'Easy' ? 'bg-success/10 text-success' : ex.difficulty === 'Medium' ? 'bg-warning/10 text-warning' : 'bg-error/10 text-error'">{{ difficultyFromApi[ex.difficulty] || ex.difficulty }}</span>
              <div @click="togglePublished(ex.id)" class="cursor-pointer inline-flex items-center gap-1 px-2 py-0.5 rounded-full" :class="ex.published ? 'bg-success/10' : 'bg-warning/10'">
                <div class="w-1.5 h-1.5 rounded-full" :class="ex.published ? 'bg-success' : 'bg-warning'"></div>
                <span class="text-xs" :class="ex.published ? 'text-success' : 'text-warning'">{{ ex.published ? 'Publicado' : 'Rascunho' }}</span>
              </div>
              <span class="bg-brand/10 text-brand text-xs px-2 py-0.5 rounded-chip truncate max-w-[120px]" :title="ex.discipline">{{ ex.discipline }}</span>
            </div>
            <p class="text-text-secondary text-xs mt-1.5 truncate" :title="ex.topic_name">{{ ex.topic_name }}</p>
          </div>
          <div v-if="filteredExercises.length === 0" class="py-8 text-center text-text-secondary text-sm">Nenhum exercício encontrado.</div>
          <div v-if="totalPages > 1" class="flex items-center justify-between py-2">
            <p class="text-text-secondary text-xs">Página {{ currentPage }} de {{ totalPages }}</p>
            <div class="flex gap-2">
              <button @click="currentPage--" :disabled="currentPage === 1" class="px-3 py-1.5 rounded-btn text-xs font-bold bg-surface border border-white/10 disabled:opacity-30">Anterior</button>
              <button @click="currentPage++" :disabled="currentPage === totalPages" class="px-3 py-1.5 rounded-btn text-xs font-bold bg-surface border border-white/10 disabled:opacity-30">Seguinte</button>
            </div>
          </div>
        </div>

        <!-- Tabela desktop -->
        <div
          class="hidden sm:block bg-surface rounded-card border border-white/5 overflow-x-auto relative"
        >
          <div
            v-if="exerciseStore.isLoading"
            class="absolute inset-0 bg-black/40 backdrop-blur-sm z-20 flex items-center justify-center"
          >
            <i class="pi pi-spinner pi-spin text-brand text-3xl"></i>
          </div>

          <table class="w-full text-left min-w-[900px]">
            <thead
              class="bg-black/20 text-text-secondary uppercase text-[10px] tracking-widest"
            >
              <tr>
                <th class="px-6 py-4 font-semibold w-10">#</th>
                <th class="px-6 py-4 font-semibold">Exercício</th>
                <th class="px-6 py-4 font-semibold text-center">Tipo</th>
                <th class="px-6 py-4 font-semibold text-center">Disciplina</th>
                <th class="px-6 py-4 font-semibold text-center">Tópico</th>
                <th class="px-6 py-4 font-semibold text-center">Dificuldade</th>
                <th class="px-6 py-4 font-semibold text-center">Estado</th>
                <th class="px-6 py-4 font-semibold text-right">Ações</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
              <tr
                v-for="(ex, idx) in paginatedExercises"
                :key="ex.id"
                class="hover:bg-white/[0.02] transition-colors group"
              >
                <td class="px-6 py-4 text-text-secondary text-xs">
                  {{ (currentPage - 1) * pageSize + idx + 1 }}
                </td>
                <td class="px-6 py-4 max-w-[260px]">
                  <p class="font-medium text-sm truncate" :title="ex.title">
                    {{ ex.title }}
                  </p>
                </td>
                <td class="px-6 py-4 text-center whitespace-nowrap">
                  <span
                    class="text-xs font-bold px-3 py-1 rounded-chip"
                    :class="typeClass(ex.type)"
                    :title="typeLabel(ex.type)"
                  >
                    {{ typeLabel(ex.type) }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center max-w-[140px]">
                  <span
                    class="bg-brand/10 text-brand text-xs font-bold px-3 py-1 rounded-chip truncate block"
                    :title="ex.discipline"
                  >
                    {{ ex.discipline }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center max-w-[160px]">
                  <span
                    class="text-text-secondary text-xs truncate block"
                    :title="ex.topic_name"
                  >
                    {{ ex.topic_name }}
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
                    {{ difficultyFromApi[ex.difficulty] || ex.difficulty }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center">
                  <div
                    @click="togglePublished(ex.id)"
                    class="cursor-pointer flex flex-col items-center gap-1"
                    :class="{
                      'opacity-50 pointer-events-none': exerciseStore.isLoading,
                    }"
                  >
                    <div
                      class="w-3 h-3 rounded-full"
                      :class="ex.published ? 'bg-success' : 'bg-warning'"
                    ></div>
                    <span class="text-xs whitespace-nowrap">{{
                      ex.published ? 'Publicado' : 'Rascunho'
                    }}</span>
                  </div>
                </td>
                <td class="px-6 py-4 text-right">
                  <div
                    class="flex justify-end gap-3 opacity-0 group-hover:opacity-100 transition-opacity"
                    :class="{ 'pointer-events-none': exerciseStore.isLoading }"
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
                      title="Editar"
                    >
                      <i class="pi pi-pencil"></i>
                    </button>
                    <button
                      @click="togglePublished(ex.id)"
                      class="text-text-secondary hover:text-success"
                      :title="ex.published ? 'Despublicar' : 'Publicar'"
                    >
                      <i
                        :class="
                          ex.published ? 'pi pi-eye-slash' : 'pi pi-check'
                        "
                      ></i>
                    </button>
                    <button
                      @click="removeExercise(ex.id)"
                      class="text-text-secondary hover:text-error"
                      title="Eliminar"
                    >
                      <i class="pi pi-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>

          <div
            v-if="filteredExercises.length === 0"
            class="p-8 text-center text-text-secondary"
          >
            Nenhum exercício encontrado com os filtros atuais.
          </div>

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
        <!-- fim tabela desktop -->

        <!-- ─── Modal de Detalhe ─────────────────────────────────────────── -->
        <Teleport to="body">
          <div
            v-if="detailExercise"
            class="fixed inset-0 z-50 flex items-center justify-center p-4"
          >
            <div
              class="absolute inset-0 bg-black/60 backdrop-blur-sm"
              @click="detailExercise = null"
            ></div>
            <div
              class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-4 sm:p-8 shadow-2xl z-10 max-h-[90vh] overflow-y-auto"
            >
              <div class="flex justify-between items-center mb-4">
                <div class="flex items-center gap-2 flex-wrap">
                  <span
                    class="bg-brand/10 text-brand text-xs font-bold px-3 py-1 rounded-chip"
                    >{{ detailExercise.discipline }}</span
                  >
                  <span
                    class="text-xs font-bold px-3 py-1 rounded-chip"
                    :class="typeClass(detailExercise.type)"
                    >{{ typeLabel(detailExercise.type) }}</span
                  >
                  <span
                    class="text-xs font-bold px-3 py-1 rounded-chip"
                    :class="
                      detailExercise.difficulty === 'Easy'
                        ? 'bg-success/10 text-success'
                        : detailExercise.difficulty === 'Medium'
                          ? 'bg-warning/10 text-warning'
                          : 'bg-error/10 text-error'
                    "
                    >{{
                      difficultyFromApi[detailExercise.difficulty] ||
                      detailExercise.difficulty
                    }}</span
                  >
                  <span
                    class="text-xs font-bold px-3 py-1 rounded-chip"
                    :class="
                      detailExercise.published
                        ? 'bg-success/10 text-success'
                        : 'bg-warning/10 text-warning'
                    "
                  >
                    {{ detailExercise.published ? 'Publicado' : 'Rascunho' }}
                  </span>
                </div>
                <button
                  @click="detailExercise = null"
                  class="text-text-secondary hover:text-white"
                >
                  <i class="pi pi-times"></i>
                </button>
              </div>

              <p class="text-xs text-text-secondary mb-3">
                {{ detailExercise.topic_name }}
              </p>
              <h4 class="font-bold mb-4">{{ detailExercise.title }}</h4>

              <div class="space-y-2 mb-4">
                <template v-if="detailExercise.type === 'Multiple Choice'">
                  <div
                    v-for="(opt, i) in detailExercise.options"
                    :key="i"
                    class="flex items-center gap-3 p-3 rounded-btn border text-sm"
                    :class="
                      isCorrectOption(detailExercise, i)
                        ? 'border-success/30 bg-success/5 text-success'
                        : 'border-white/5 bg-background text-text-secondary'
                    "
                  >
                    <span
                      class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold shrink-0"
                      :class="
                        isCorrectOption(detailExercise, i)
                          ? 'bg-success/20'
                          : 'bg-white/5'
                      "
                    >
                      {{ String.fromCharCode(65 + i) }}
                    </span>
                    {{ opt }}
                    <span
                      v-if="isCorrectOption(detailExercise, i)"
                      class="ml-auto text-xs"
                      >✓</span
                    >
                  </div>
                </template>
                <template v-else-if="detailExercise.type === 'True/False'">
                  <div
                    v-for="opt in ['Verdadeiro', 'Falso']"
                    :key="opt"
                    class="flex items-center gap-3 p-3 rounded-btn border text-sm"
                    :class="
                      isTrueFalseCorrect(detailExercise, opt)
                        ? 'border-success/30 bg-success/5 text-success'
                        : 'border-white/5 bg-background text-text-secondary'
                    "
                  >
                    <span
                      class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold shrink-0"
                      :class="
                        isTrueFalseCorrect(detailExercise, opt)
                          ? 'bg-success/20'
                          : 'bg-white/5'
                      "
                    >
                      {{ opt === 'Verdadeiro' ? 'V' : 'F' }}
                    </span>
                    {{ opt }}
                    <span
                      v-if="isTrueFalseCorrect(detailExercise, opt)"
                      class="ml-auto text-xs"
                      >✓ Correto</span
                    >
                  </div>
                </template>
              </div>

              <div
                v-if="detailExercise.explanation"
                class="bg-background p-4 rounded-btn border border-white/5"
              >
                <p
                  class="text-xs font-bold text-brand uppercase tracking-widest mb-1"
                >
                  Explicação
                </p>
                <p class="text-sm text-text-secondary">
                  {{ detailExercise.explanation }}
                </p>
              </div>

              <div class="flex justify-end mt-6">
                <button
                  @click="
                    openEdit(detailExercise);
                    detailExercise = null;
                  "
                  class="inline-flex items-center gap-2 px-5 py-2.5 bg-brand text-white rounded-btn hover:bg-brand/80 transition-all text-sm font-semibold"
                >
                  <i class="pi pi-pencil"></i> Editar Exercício
                </button>
              </div>
            </div>
          </div>
        </Teleport>

        <!-- ─── Modal de Edição ──────────────────────────────────────────── -->
        <Teleport to="body">
          <div
            v-if="editExercise"
            class="fixed inset-0 z-50 flex items-center justify-center p-4"
          >
            <div
              class="absolute inset-0 bg-black/60 backdrop-blur-sm"
              @click="closeEdit"
            ></div>
            <div
              class="relative bg-surface border border-white/10 rounded-card w-full max-w-2xl shadow-2xl z-10 max-h-[92vh] overflow-y-auto"
            >
              <div
                class="flex justify-between items-center px-4 sm:px-8 py-4 sm:py-6 border-b border-white/5"
              >
                <div>
                  <p
                    class="text-brand font-bold text-xs uppercase tracking-widest mb-0.5"
                  >
                    A editar
                  </p>
                  <h4 class="font-bold text-lg">Editar Exercício</h4>
                </div>
                <button
                  @click="closeEdit"
                  class="text-text-secondary hover:text-white"
                >
                  <i class="pi pi-times"></i>
                </button>
              </div>

              <div class="px-4 sm:px-8 py-4 sm:py-6 space-y-6">
                <div>
                  <label
                    class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2"
                    >Pergunta</label
                  >
                  <textarea
                    v-model="editForm.question"
                    rows="3"
                    class="w-full bg-background border border-white/10 rounded-btn px-4 py-3 text-sm outline-none focus:border-brand resize-none transition-colors"
                    placeholder="Texto da pergunta..."
                  ></textarea>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div>
                    <label
                      class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2"
                      >Tipo</label
                    >
                    <select
                      v-model="editForm.type"
                      class="w-full bg-background border border-white/10 px-3 py-2.5 rounded-btn text-sm outline-none focus:border-brand"
                    >
                      <option value="Multiple Choice">Escolha Múltipla</option>
                      <option value="True/False">Verdadeiro/Falso</option>
                    </select>
                  </div>
                  <div>
                    <label
                      class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2"
                      >Dificuldade</label
                    >
                    <select
                      v-model="editForm.difficulty"
                      class="w-full bg-background border border-white/10 px-3 py-2.5 rounded-btn text-sm outline-none focus:border-brand"
                    >
                      <option value="Easy">Fácil</option>
                      <option value="Medium">Médio</option>
                      <option value="Hard">Difícil</option>
                    </select>
                  </div>
                  <div>
                    <label
                      class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2"
                      >Tópico</label
                    >
                    <select
                      v-model="editForm.topic_name"
                      class="w-full bg-background border border-white/10 px-3 py-2.5 rounded-btn text-sm outline-none focus:border-brand"
                    >
                      <option v-for="t in topicsForEdit" :key="t" :value="t">
                        {{ t }}
                      </option>
                    </select>
                  </div>
                </div>

                <div v-if="editForm.type === 'Multiple Choice'">
                  <label
                    class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-3"
                  >
                    Opções
                    <span
                      class="text-text-secondary font-normal normal-case ml-1"
                      >(clica para marcar como correta)</span
                    >
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
                        class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 transition-all border"
                        :class="
                          editForm.correct === i
                            ? 'bg-success/20 border-success/40 text-success'
                            : 'bg-white/5 border-white/10 text-text-secondary hover:border-white/30'
                        "
                      >
                        {{ String.fromCharCode(65 + i) }}
                      </button>
                      <input
                        v-model="editForm.options[i]"
                        type="text"
                        class="flex-1 bg-background border px-3 py-2 rounded-btn text-sm outline-none focus:border-brand transition-colors"
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

                <div v-else-if="editForm.type === 'True/False'">
                  <label
                    class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-3"
                    >Resposta Correta</label
                  >
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

                <div>
                  <label
                    class="block text-xs font-bold text-text-secondary uppercase tracking-widest mb-2"
                  >
                    Explicação
                    <span
                      class="text-text-secondary font-normal normal-case ml-1"
                      >(opcional)</span
                    >
                  </label>
                  <textarea
                    v-model="editForm.explanation"
                    rows="3"
                    class="w-full bg-background border border-white/10 rounded-btn px-4 py-3 text-sm outline-none focus:border-brand resize-none transition-colors"
                    placeholder="Explica a resposta correta..."
                  ></textarea>
                </div>

                <div
                  class="flex items-center justify-between p-4 bg-background rounded-btn border border-white/5"
                >
                  <div>
                    <p class="text-sm font-bold">Estado de publicação</p>
                    <p class="text-xs text-text-secondary mt-0.5">
                      {{
                        editForm.published
                          ? 'Visível para os alunos'
                          : 'Não visível para os alunos'
                      }}
                    </p>
                  </div>
                  <button
                    type="button"
                    @click="editForm.published = !editForm.published"
                    class="relative w-12 h-6 rounded-full transition-colors"
                    :class="editForm.published ? 'bg-success' : 'bg-white/10'"
                  >
                    <span
                      class="absolute top-1 w-4 h-4 rounded-full bg-white transition-all"
                      :class="editForm.published ? 'left-7' : 'left-1'"
                    ></span>
                  </button>
                </div>

                <div
                  v-if="editError"
                  class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-btn text-sm"
                >
                  <i class="pi pi-exclamation-triangle mr-2"></i>{{ editError }}
                </div>
              </div>

              <div
                class="flex justify-end gap-3 px-4 sm:px-8 py-4 sm:py-5 border-t border-white/5"
              >
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
                  <i
                    :class="isSaving ? 'pi pi-spinner pi-spin' : 'pi pi-check'"
                  ></i>
                  {{ isSaving ? 'A guardar...' : 'Guardar Alterações' }}
                </button>
              </div>
            </div>
          </div>
        </Teleport>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { useExerciseStore } from '../stores/exerciseStore';

const authStore = useAuthStore();
const exerciseStore = useExerciseStore();

onMounted(async () => {
  await exerciseStore.loadExercises();
});

// ─── Filtros ───────────────────────────────────────────────────────────────

const statusFilter = ref('Todos');
const disciplineFilter = ref('');
const topicFilter = ref('');
const difficultyFilter = ref('');
const typeFilter = ref('');
const currentPage = ref(1);
const pageSize = 15;

const difficultyFromApi = { Easy: 'Fácil', Medium: 'Médio', Hard: 'Difícil' };

const userDisciplineIds = computed(
  () => authStore.user?.course_units?.map((uc) => uc.id) || [],
);

const availableTopics = computed(() => {
  try {
    const base = disciplineFilter.value
      ? exerciseStore.exercises.filter(
          (e) => e.id_uc === Number(disciplineFilter.value),
        )
      : exerciseStore.exercises;
    return [...new Set(base.map((e) => e.topic_name).filter(Boolean))].sort();
  } catch {
    return [];
  }
});

watch(disciplineFilter, () => {
  topicFilter.value = '';
  currentPage.value = 1;
});
watch([statusFilter, topicFilter, difficultyFilter, typeFilter], () => {
  currentPage.value = 1;
});

const hasActiveFilters = computed(
  () =>
    statusFilter.value !== 'Todos' ||
    !!disciplineFilter.value ||
    !!topicFilter.value ||
    !!difficultyFilter.value ||
    !!typeFilter.value,
);

function clearFilters() {
  statusFilter.value = 'Todos';
  disciplineFilter.value = '';
  topicFilter.value = '';
  difficultyFilter.value = '';
  typeFilter.value = '';
}

// ─── Exercícios filtrados ──────────────────────────────────────────────────

const filteredExercises = computed(() => {
  try {
    let list = Array.isArray(exerciseStore.exercises)
      ? [...exerciseStore.exercises]
      : [];
    const userIds = userDisciplineIds.value;
    if (userIds.length > 0)
      list = list.filter((e) => userIds.includes(e?.id_uc));
    if (statusFilter.value === 'Publicados')
      list = list.filter((e) => e?.published === true);
    else if (statusFilter.value === 'Rascunhos')
      list = list.filter((e) => e?.published === false);
    if (disciplineFilter.value)
      list = list.filter((e) => e?.id_uc === Number(disciplineFilter.value));
    if (topicFilter.value)
      list = list.filter((e) => e?.topic_name === topicFilter.value);
    if (difficultyFilter.value)
      list = list.filter((e) => e?.difficulty === difficultyFilter.value);
    if (typeFilter.value)
      list = list.filter((e) => e?.type === typeFilter.value);
    return list;
  } catch (e) {
    console.error('Erro ao filtrar:', e);
    return [];
  }
});

const totalPages = computed(() =>
  Math.max(1, Math.ceil(filteredExercises.value.length / pageSize)),
);
const paginatedExercises = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  return filteredExercises.value.slice(start, start + pageSize);
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
  topic_name: '',
  options: ['', '', '', ''],
  correct: 0,
  explanation: '',
  published: false,
});

const topicsForEdit = computed(() => {
  if (!editExercise.value) return [];
  return [
    ...new Set(
      exerciseStore.exercises
        .filter((e) => e.id_uc === editExercise.value.id_uc)
        .map((e) => e.topic_name)
        .filter(Boolean),
    ),
  ].sort();
});

function openEdit(ex) {
  editExercise.value = ex;
  editError.value = null;
  let correct;
  if (ex.type === 'Multiple Choice') {
    const c = ex.correct ?? ex.solution?.correct;
    if (typeof c === 'number') correct = c;
    else if (typeof c === 'string' && /^[A-Da-d]$/.test(c))
      correct = c.toUpperCase().charCodeAt(0) - 65;
    else if (typeof c === 'string' && !isNaN(Number(c))) correct = Number(c);
    else correct = 0;
  } else {
    const c = ex.correct ?? ex.solution?.correct;
    const cStr = String(c ?? '').toLowerCase();
    correct = cStr === 'true' || cStr === 'verdadeiro' ? 'True' : 'False';
  }
  editForm.value = {
    question: ex.question || ex.title || '',
    type: ex.type || 'Multiple Choice',
    difficulty: ex.difficulty || 'Easy',
    topic_name: ex.topic_name || '',
    options: ex.options?.length ? [...ex.options] : ['', '', '', ''],
    correct,
    explanation: ex.explanation || '',
    published: ex.published ?? false,
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
    // Normalize correct to a letter ("A", "B", "C", "D") so Flutter can parse it
    const rawCorrect = editForm.value.correct;
    const correctLetter =
      editForm.value.type === 'Multiple Choice'
        ? typeof rawCorrect === 'number'
          ? String.fromCharCode(65 + rawCorrect)
          : String(rawCorrect ?? 'A').toUpperCase()
        : rawCorrect; // True/False: keeps "True"/"False"
    const solution =
      editForm.value.type === 'Multiple Choice'
        ? { options: editForm.value.options, correct: correctLetter }
        : { correct: correctLetter };
    await exerciseStore.updateExercise(editExercise.value.id, {
      question: editForm.value.question,
      type: editForm.value.type,
      difficulty: editForm.value.difficulty,
      topic_name: editForm.value.topic_name,
      solution,
      explanation: editForm.value.explanation,
      published: editForm.value.published,
    });
    closeEdit();
  } catch {
    editError.value = 'Erro ao guardar. Tenta novamente.';
  } finally {
    isSaving.value = false;
  }
}

// ─── Ações da tabela ──────────────────────────────────────────────────────

async function togglePublished(id) {
  if (exerciseStore.isLoading) return;
  await exerciseStore.togglePublished(id);
}

async function removeExercise(id) {
  if (exerciseStore.isLoading) return;
  if (!confirm('Tem a certeza de que pretende eliminar este exercício?'))
    return;
  await exerciseStore.removeExercise(id);
}

// ─── Helpers ──────────────────────────────────────────────────────────────

const typeLabels = {
  'Multiple Choice': 'Escolha Múltipla',
  'True/False': 'V/F',
};
const typeLabel = (type) => typeLabels[type] || type || 'Escolha Múltipla';
const typeClass = (type) =>
  ({
    'Multiple Choice': 'bg-brand/10 text-brand',
    'True/False': 'bg-purple-500/10 text-purple-400',
  })[type] || 'bg-brand/10 text-brand';

function isCorrectOption(ex, index) {
  const c = ex.correct ?? ex.solution?.correct;
  if (c === null || c === undefined) return false;
  if (typeof c === 'number') return c === index;
  if (typeof c === 'string') {
    if (/^[A-Da-d]$/.test(c))
      return c.toUpperCase().charCodeAt(0) - 65 === index;
    if (!isNaN(Number(c))) return Number(c) === index;
  }
  return false;
}

function isTrueFalseCorrect(ex, label) {
  const c = ex.correct ?? ex.solution?.correct;
  if (c === null || c === undefined) return false;
  const cStr = String(c).toLowerCase();
  const isTrue = cStr === 'true' || cStr === 'verdadeiro';
  return label === 'Verdadeiro' ? isTrue : !isTrue;
}
</script>
