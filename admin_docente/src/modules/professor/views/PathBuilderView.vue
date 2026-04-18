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
            <div
              class="w-12 h-12 rounded-full bg-warning/10 flex items-center justify-center"
            >
              <i class="pi pi-exclamation-circle text-warning text-xl"></i>
            </div>
            <div>
              <p class="font-bold">Solicitar Acesso a Disciplinas</p>
              <p class="text-text-secondary text-sm">
                Contacte o administrador da plataforma para atribuir unidades
                curriculares.
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
        v-if="pathStore.isLoading && !pathStore.hasLoaded"
        class="flex items-center justify-center py-20"
      >
        <div class="text-center">
          <i class="pi pi-spinner pi-spin text-brand text-4xl mb-4 block"></i>
          <p class="text-text-secondary">A carregar percursos...</p>
        </div>
      </div>

      <div class="space-y-8" v-else>
        <div>
          <p
            class="text-brand font-bold text-sm uppercase tracking-widest mb-1"
          >
            Caminho Base
          </p>
          <h3 class="text-3xl font-bold">Construtor de Percurso</h3>
          <p class="text-text-secondary mt-1">
            Um percurso por disciplina, gerado automaticamente pelos tópicos e
            exercícios publicados.
          </p>
        </div>

        <div
          v-if="pathStore.error"
          class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
        >
          <i class="pi pi-exclamation-triangle mr-2"></i>{{ pathStore.error }}
        </div>

        <div class="grid grid-cols-3 gap-6">
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Percursos</p>
            <p class="text-3xl font-bold mt-2">{{ pathStore.paths.length }}</p>
          </div>
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Total Tópicos</p>
            <p class="text-3xl font-bold mt-2 text-brand">
              {{ pathStore.totalModules }}
            </p>
          </div>
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Exercícios no Percurso</p>
            <p class="text-3xl font-bold mt-2 text-warning">
              {{ pathStore.totalExercisesInPaths }}
            </p>
          </div>
        </div>

        <div v-if="pathStore.paths.length > 0">
          <div class="flex items-center gap-3 mb-6 flex-wrap">
            <button
              v-for="p in pathStore.paths"
              :key="p.id_uc"
              @click="selectPath(p.id_uc)"
              :class="
                selectedPathId === p.id_uc
                  ? 'bg-brand text-white'
                  : 'bg-surface text-text-secondary border border-white/10 hover:border-brand/30'
              "
              class="px-5 py-2.5 rounded-chip text-sm font-bold transition-all flex items-center gap-2"
            >
              <span>{{ p.name }}</span>
              <span class="text-xs opacity-70"
                >{{ p.total_topics }} tópicos</span
              >
            </button>
          </div>

          <div v-if="selectedPath" class="grid grid-cols-12 gap-6">
            <!-- Coluna esquerda: checkpoints -->
            <div class="col-span-5">
              <div class="bg-surface rounded-card border border-white/5 p-6">
                <div class="mb-6">
                  <h4 class="text-lg font-bold">{{ selectedPath.name }}</h4>
                  <p class="text-text-secondary text-xs mt-0.5">
                    {{ selectedPath.total_topics }} tópicos ·
                    {{ selectedPath.total_exercises }} exercícios
                  </p>
                </div>

                <div class="relative">
                  <div
                    v-for="(checkpoint, idx) in selectedPath.checkpoints"
                    :key="checkpoint.topic_name"
                    class="relative"
                  >
                    <div v-if="idx > 0" class="flex justify-center">
                      <div
                        class="w-0.5 h-8"
                        :class="
                          checkpoint.exercises.length > 0
                            ? 'bg-brand/50'
                            : 'bg-gray-700'
                        "
                      ></div>
                    </div>
                    <div
                      @click="
                        selectedCheckpointName = checkpoint.topic_name;
                        cancelEdit();
                      "
                      class="relative cursor-pointer group"
                      :class="{ 'ml-12': idx % 2 !== 0 }"
                    >
                      <div
                        class="flex items-center gap-4 p-4 rounded-card border transition-all"
                        :class="
                          selectedCheckpointName === checkpoint.topic_name
                            ? 'bg-brand/10 border-brand shadow-lg shadow-brand/10'
                            : checkpoint.exercises.length > 0
                              ? 'bg-background border-white/10 hover:border-brand/30'
                              : 'bg-background border-white/5 hover:border-warning/30 opacity-60'
                        "
                      >
                        <div
                          class="w-14 h-14 rounded-full flex items-center justify-center text-xl font-bold shrink-0 shadow-lg"
                          :class="
                            checkpoint.exercises.length > 0
                              ? 'bg-brand text-white'
                              : 'bg-gray-700 text-text-secondary'
                          "
                        >
                          {{ checkpoint.topic_order }}
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="font-bold text-sm truncate">
                            {{ checkpoint.topic_name }}
                          </p>
                          <p class="text-text-secondary text-xs mt-0.5">
                            {{ checkpoint.exercises.length }} exercício(s)
                          </p>
                        </div>
                        <i
                          v-if="checkpoint.exercises.length === 0"
                          class="pi pi-exclamation-triangle text-warning text-xs"
                          title="Sem exercícios publicados"
                        ></i>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Coluna direita: exercícios -->
            <div class="col-span-7 space-y-4">
              <div
                v-if="!selectedCheckpoint"
                class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center"
              >
                <i
                  class="pi pi-arrow-left text-4xl text-brand/30 mb-4 block"
                ></i>
                <p class="text-text-secondary">
                  Selecione um tópico à esquerda para ver os exercícios.
                </p>
              </div>

              <template v-else>
                <!-- Header do checkpoint -->
                <div class="bg-surface rounded-card border border-white/5 p-6">
                  <div class="flex items-center justify-between mb-2">
                    <div class="flex items-center gap-3">
                      <span
                        class="bg-brand/10 text-brand text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                      >
                        Tópico {{ selectedCheckpoint.topic_order }}
                      </span>
                      <span
                        class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                        :class="
                          selectedCheckpoint.exercises.length > 0
                            ? 'bg-success/10 text-success'
                            : 'bg-warning/10 text-warning'
                        "
                      >
                        {{
                          selectedCheckpoint.exercises.length > 0
                            ? 'Com exercícios'
                            : 'Sem exercícios'
                        }}
                      </span>
                    </div>
                    <button
                      @click="openAddModal"
                      class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold bg-brand text-white rounded-btn hover:bg-brand/80 transition-all"
                    >
                      <i class="pi pi-plus text-[10px]"></i>
                      Adicionar Exercício
                    </button>
                  </div>
                  <h4 class="text-xl font-bold">
                    {{ selectedCheckpoint.topic_name }}
                  </h4>
                  <p class="text-text-secondary text-xs mt-2">
                    <i class="pi pi-info-circle mr-1"></i>
                    Exercícios ordenados por dificuldade: Fácil → Médio →
                    Difícil.
                  </p>
                </div>

                <!-- Sem exercícios -->
                <div
                  v-if="selectedCheckpoint.exercises.length === 0"
                  class="bg-surface rounded-card border border-white/5 border-dashed p-8 text-center"
                >
                  <p class="text-text-secondary text-sm">
                    Nenhum exercício publicado neste tópico.
                    <button
                      @click="openAddModal"
                      class="text-brand hover:underline ml-1"
                    >
                      Adicionar agora
                    </button>
                  </p>
                </div>

                <!-- Lista de exercícios -->
                <div
                  v-for="(ex, eIdx) in selectedCheckpoint.exercises"
                  :key="ex.id_exercise"
                  class="bg-surface rounded-card border overflow-hidden transition-all"
                  :class="
                    editingId === ex.id_exercise
                      ? 'border-brand/40'
                      : 'border-white/5'
                  "
                >
                  <!-- Vista normal -->
                  <div v-if="editingId !== ex.id_exercise" class="p-5">
                    <div class="flex items-center gap-2 mb-3">
                      <span class="text-brand text-xs font-bold"
                        >Q{{ eIdx + 1 }}</span
                      >
                      <span
                        class="text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-chip"
                        :class="
                          ex.difficulty === 'Easy'
                            ? 'bg-success/10 text-success'
                            : ex.difficulty === 'Medium'
                              ? 'bg-warning/10 text-warning'
                              : 'bg-error/10 text-error'
                        "
                      >
                        {{ difficultyLabel(ex.difficulty) }}
                      </span>
                      <span
                        class="text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-chip bg-brand/10 text-brand"
                      >
                        {{ typeLabel(ex.type) }}
                      </span>
                    </div>

                    <p class="font-medium text-sm mb-3">{{ ex.question }}</p>

                    <!-- Multiple Choice -->
                    <div
                      v-if="
                        ex.type === 'Multiple Choice' && ex.solution?.options
                      "
                      class="grid grid-cols-2 gap-2"
                    >
                      <div
                        v-for="(opt, oIdx) in ex.solution.options"
                        :key="oIdx"
                        class="text-xs p-2.5 rounded-btn border"
                        :class="
                          isMCCorrect(ex, oIdx)
                            ? 'bg-success/10 border-success/30 text-success'
                            : 'bg-background border-white/5 text-text-secondary'
                        "
                      >
                        <span class="font-bold mr-2">{{
                          String.fromCharCode(65 + oIdx)
                        }}</span
                        >{{ opt }}
                      </div>
                    </div>

                    <!-- True/False -->
                    <div
                      v-else-if="ex.type === 'True/False'"
                      class="flex gap-2"
                    >
                      <div
                        v-for="opt in ['Verdadeiro', 'Falso']"
                        :key="opt"
                        class="text-xs p-2.5 rounded-btn border flex-1 text-center"
                        :class="
                          isTrueFalseCorrect(ex, opt)
                            ? 'bg-success/10 border-success/30 text-success'
                            : 'bg-background border-white/5 text-text-secondary'
                        "
                      >
                        <span class="font-bold mr-1">{{
                          opt === 'Verdadeiro' ? 'V' : 'F'
                        }}</span
                        >{{ opt }}
                      </div>
                    </div>

                    <!-- Explicação -->
                    <div
                      v-if="ex.explanation"
                      class="mt-3 text-xs text-text-secondary"
                    >
                      <i class="pi pi-info-circle mr-1"></i>{{ ex.explanation }}
                    </div>

                    <!-- Acções -->
                    <div
                      class="flex items-center gap-2 mt-4 pt-3 border-t border-white/5"
                    >
                      <button
                        @click="startEdit(ex)"
                        class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold bg-brand/10 text-brand rounded-btn hover:bg-brand/20 transition-all"
                      >
                        <i class="pi pi-pencil text-[10px]"></i>
                        Editar
                      </button>
                      <button
                        @click="removeExercise(ex.id_exercise)"
                        :disabled="removingId === ex.id_exercise"
                        class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold bg-error/10 text-error rounded-btn hover:bg-error/20 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <i
                          :class="
                            removingId === ex.id_exercise
                              ? 'pi pi-spinner pi-spin'
                              : 'pi pi-eye-slash'
                          "
                          class="text-[10px]"
                        ></i>
                        {{
                          removingId === ex.id_exercise
                            ? 'A remover...'
                            : 'Remover do percurso'
                        }}
                      </button>
                    </div>
                  </div>

                  <!-- Formulário de edição inline -->
                  <div v-else class="p-5 bg-brand/5">
                    <div class="flex items-center justify-between mb-5">
                      <p
                        class="text-xs font-bold text-brand uppercase tracking-widest"
                      >
                        <i class="pi pi-pencil mr-1.5"></i>A editar Q{{
                          eIdx + 1
                        }}
                      </p>
                      <button
                        @click="cancelEdit"
                        class="text-text-secondary hover:text-white text-xs transition-colors"
                      >
                        <i class="pi pi-times mr-1"></i>Cancelar
                      </button>
                    </div>

                    <div class="mb-4">
                      <label
                        class="block text-xs font-bold text-text-secondary mb-1.5"
                        >Pergunta</label
                      >
                      <textarea
                        v-model="editForm.question"
                        rows="3"
                        class="w-full bg-background border border-white/10 rounded-btn px-3 py-2 text-sm text-white placeholder-text-secondary focus:outline-none focus:border-brand/50 resize-none"
                      ></textarea>
                    </div>

                    <div class="mb-4">
                      <label
                        class="block text-xs font-bold text-text-secondary mb-1.5"
                        >Dificuldade</label
                      >
                      <div class="flex gap-2">
                        <button
                          v-for="d in ['Easy', 'Medium', 'Hard']"
                          :key="d"
                          @click="editForm.difficulty = d"
                          :class="
                            editForm.difficulty === d
                              ? d === 'Easy'
                                ? 'bg-success/20 text-success border-success/40'
                                : d === 'Medium'
                                  ? 'bg-warning/20 text-warning border-warning/40'
                                  : 'bg-error/20 text-error border-error/40'
                              : 'bg-background text-text-secondary border-white/10 hover:border-white/20'
                          "
                          class="flex-1 px-3 py-1.5 text-xs font-bold rounded-btn border transition-all"
                        >
                          {{ difficultyLabel(d) }}
                        </button>
                      </div>
                    </div>

                    <div v-if="ex.type === 'Multiple Choice'" class="mb-4">
                      <label
                        class="block text-xs font-bold text-text-secondary mb-1.5"
                      >
                        Opções
                        <span class="font-normal opacity-60"
                          >(clica na letra para marcar como correta)</span
                        >
                      </label>
                      <div class="space-y-2">
                        <div
                          v-for="(opt, oIdx) in editForm.options"
                          :key="oIdx"
                          class="flex items-center gap-2"
                        >
                          <button
                            @click="editForm.correct = oIdx"
                            :class="
                              editForm.correct === oIdx
                                ? 'bg-success/20 border-success/40 text-success'
                                : 'bg-background border-white/10 text-text-secondary hover:border-white/20'
                            "
                            class="w-7 h-7 shrink-0 rounded-full border text-xs font-bold transition-all"
                          >
                            {{ String.fromCharCode(65 + oIdx) }}
                          </button>
                          <input
                            v-model="editForm.options[oIdx]"
                            class="flex-1 bg-background border border-white/10 rounded-btn px-3 py-1.5 text-sm text-white focus:outline-none focus:border-brand/50"
                            :placeholder="`Opção ${String.fromCharCode(65 + oIdx)}`"
                          />
                        </div>
                      </div>
                    </div>

                    <div v-if="ex.type === 'True/False'" class="mb-4">
                      <label
                        class="block text-xs font-bold text-text-secondary mb-1.5"
                        >Resposta correta</label
                      >
                      <div class="flex gap-2">
                        <button
                          @click="editForm.correct = 'true'"
                          :class="
                            String(editForm.correct).toLowerCase() === 'true'
                              ? 'bg-success/20 text-success border-success/40'
                              : 'bg-background text-text-secondary border-white/10 hover:border-white/20'
                          "
                          class="flex-1 px-3 py-1.5 text-xs font-bold rounded-btn border transition-all"
                        >
                          Verdadeiro
                        </button>
                        <button
                          @click="editForm.correct = 'false'"
                          :class="
                            String(editForm.correct).toLowerCase() === 'false'
                              ? 'bg-error/20 text-error border-error/40'
                              : 'bg-background text-text-secondary border-white/10 hover:border-white/20'
                          "
                          class="flex-1 px-3 py-1.5 text-xs font-bold rounded-btn border transition-all"
                        >
                          Falso
                        </button>
                      </div>
                    </div>

                    <div class="mb-5">
                      <label
                        class="block text-xs font-bold text-text-secondary mb-1.5"
                        >Explicação (opcional)</label
                      >
                      <input
                        v-model="editForm.explanation"
                        class="w-full bg-background border border-white/10 rounded-btn px-3 py-2 text-sm text-white focus:outline-none focus:border-brand/50"
                        placeholder="Justificação da resposta correta..."
                      />
                    </div>

                    <div class="flex items-center gap-2">
                      <button
                        @click="saveEdit(ex.id_exercise, ex.type)"
                        :disabled="savingEdit"
                        class="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold bg-brand text-white rounded-btn hover:bg-brand/80 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <i
                          :class="
                            savingEdit ? 'pi pi-spinner pi-spin' : 'pi pi-check'
                          "
                          class="text-[10px]"
                        ></i>
                        {{ savingEdit ? 'A guardar...' : 'Guardar alterações' }}
                      </button>
                      <button
                        @click="cancelEdit"
                        class="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold bg-surface text-text-secondary rounded-btn hover:text-white border border-white/10 transition-all"
                      >
                        Cancelar
                      </button>
                    </div>
                  </div>
                </div>
              </template>
            </div>
          </div>
        </div>

        <div
          v-else
          class="bg-surface rounded-card border border-white/5 p-12 text-center"
        >
          <i class="pi pi-spinner pi-spin text-brand text-3xl mb-4 block"></i>
          <p class="text-text-secondary">A gerar percursos...</p>
        </div>
      </div>
    </template>

    <!-- ─── Modal: Adicionar Exercício ─────────────────────────────────────── -->
    <Teleport to="body">
      <div
        v-if="showAddModal"
        class="fixed inset-0 z-50 flex items-center justify-center"
      >
        <div
          class="absolute inset-0 bg-black/60 backdrop-blur-sm"
          @click="closeAddModal"
        ></div>
        <div
          class="relative bg-surface border border-white/10 rounded-card w-full max-w-2xl p-8 shadow-2xl z-10 max-h-[90vh] flex flex-col"
        >
          <div class="flex items-center justify-between mb-6 shrink-0">
            <div>
              <h4 class="text-xl font-bold">Adicionar Exercício</h4>
              <p class="text-text-secondary text-xs mt-0.5">
                Tópico:
                <span class="text-brand font-bold">{{
                  selectedCheckpoint?.topic_name
                }}</span>
              </p>
            </div>
            <button
              @click="closeAddModal"
              class="text-text-secondary hover:text-white"
            >
              <i class="pi pi-times"></i>
            </button>
          </div>

          <!-- Tabs -->
          <div class="flex gap-2 mb-6 shrink-0">
            <button
              @click="addTab = 'existing'"
              :class="
                addTab === 'existing'
                  ? 'bg-brand text-white'
                  : 'bg-background text-text-secondary border border-white/10 hover:border-brand/30'
              "
              class="px-4 py-2 rounded-btn text-sm font-bold transition-all"
            >
              <i class="pi pi-database mr-2"></i>Da BD
            </button>
            <button
              @click="addTab = 'new'"
              :class="
                addTab === 'new'
                  ? 'bg-brand text-white'
                  : 'bg-background text-text-secondary border border-white/10 hover:border-brand/30'
              "
              class="px-4 py-2 rounded-btn text-sm font-bold transition-all"
            >
              <i class="pi pi-plus mr-2"></i>Criar Novo
            </button>
          </div>

          <!-- Tab: Da BD -->
          <div v-if="addTab === 'existing'" class="overflow-y-auto flex-1">
            <div
              v-if="loadingDrafts"
              class="flex items-center justify-center py-12"
            >
              <i class="pi pi-spinner pi-spin text-brand text-2xl"></i>
            </div>
            <div
              v-else-if="draftExercisesForTopic.length === 0"
              class="text-center py-12"
            >
              <i class="pi pi-inbox text-4xl text-brand/30 mb-3 block"></i>
              <p class="text-text-secondary text-sm">
                Não há exercícios em rascunho para este tópico.
              </p>
              <button
                @click="addTab = 'new'"
                class="text-brand hover:underline text-sm mt-2"
              >
                Criar um novo
              </button>
            </div>
            <div v-else class="space-y-3">
              <div
                v-for="ex in draftExercisesForTopic"
                :key="ex.id_exercise"
                @click="toggleSelectDraft(ex.id_exercise)"
                class="p-4 rounded-card border cursor-pointer transition-all"
                :class="
                  selectedDraftIds.includes(ex.id_exercise)
                    ? 'border-brand bg-brand/5'
                    : 'border-white/10 hover:border-brand/30 bg-background'
                "
              >
                <div class="flex items-start gap-3">
                  <div
                    class="w-5 h-5 rounded border shrink-0 mt-0.5 flex items-center justify-center transition-all"
                    :class="
                      selectedDraftIds.includes(ex.id_exercise)
                        ? 'bg-brand border-brand'
                        : 'border-white/20'
                    "
                  >
                    <i
                      v-if="selectedDraftIds.includes(ex.id_exercise)"
                      class="pi pi-check text-white text-[10px]"
                    ></i>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2 mb-1">
                      <span
                        class="text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-chip"
                        :class="
                          ex.difficulty === 'Easy'
                            ? 'bg-success/10 text-success'
                            : ex.difficulty === 'Medium'
                              ? 'bg-warning/10 text-warning'
                              : 'bg-error/10 text-error'
                        "
                        >{{ difficultyLabel(ex.difficulty) }}</span
                      >
                      <span
                        class="text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-chip bg-brand/10 text-brand"
                      >
                        {{ typeLabel(ex.type) }}
                      </span>
                    </div>
                    <p class="text-sm font-medium">{{ ex.question }}</p>
                  </div>
                </div>
              </div>
            </div>

            <div
              v-if="draftExercisesForTopic.length > 0"
              class="mt-6 flex justify-end gap-3 shrink-0"
            >
              <button
                @click="closeAddModal"
                class="px-4 py-2 text-sm font-bold text-text-secondary border border-white/10 rounded-btn hover:text-white transition-all"
              >
                Cancelar
              </button>
              <button
                @click="addExistingToPath"
                :disabled="selectedDraftIds.length === 0 || addingExercise"
                class="inline-flex items-center gap-2 px-5 py-2 text-sm font-bold bg-brand text-white rounded-btn hover:bg-brand/80 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <i
                  :class="
                    addingExercise ? 'pi pi-spinner pi-spin' : 'pi pi-check'
                  "
                  class="text-xs"
                ></i>
                {{
                  addingExercise
                    ? 'A adicionar...'
                    : `Adicionar (${selectedDraftIds.length})`
                }}
              </button>
            </div>
          </div>

          <!-- Tab: Criar Novo -->
          <div v-if="addTab === 'new'" class="overflow-y-auto flex-1">
            <div class="space-y-4">
              <div>
                <label
                  class="block text-xs font-bold text-text-secondary mb-1.5"
                  >Tipo</label
                >
                <div class="flex gap-2">
                  <button
                    v-for="t in ['Multiple Choice', 'True/False']"
                    :key="t"
                    @click="
                      newForm.type = t;
                      resetNewFormAnswers();
                    "
                    :class="
                      newForm.type === t
                        ? 'bg-brand text-white'
                        : 'bg-background text-text-secondary border border-white/10 hover:border-brand/30'
                    "
                    class="flex-1 px-3 py-2 text-xs font-bold rounded-btn border transition-all"
                  >
                    {{ typeLabel(t) }}
                  </button>
                </div>
              </div>

              <div>
                <label
                  class="block text-xs font-bold text-text-secondary mb-1.5"
                  >Pergunta</label
                >
                <textarea
                  v-model="newForm.question"
                  rows="3"
                  class="w-full bg-background border border-white/10 rounded-btn px-3 py-2 text-sm text-white placeholder-text-secondary focus:outline-none focus:border-brand/50 resize-none"
                  placeholder="Escreve a pergunta..."
                ></textarea>
              </div>

              <div>
                <label
                  class="block text-xs font-bold text-text-secondary mb-1.5"
                  >Dificuldade</label
                >
                <div class="flex gap-2">
                  <button
                    v-for="d in ['Easy', 'Medium', 'Hard']"
                    :key="d"
                    @click="newForm.difficulty = d"
                    :class="
                      newForm.difficulty === d
                        ? d === 'Easy'
                          ? 'bg-success/20 text-success border-success/40'
                          : d === 'Medium'
                            ? 'bg-warning/20 text-warning border-warning/40'
                            : 'bg-error/20 text-error border-error/40'
                        : 'bg-background text-text-secondary border-white/10 hover:border-white/20'
                    "
                    class="flex-1 px-3 py-1.5 text-xs font-bold rounded-btn border transition-all"
                  >
                    {{ difficultyLabel(d) }}
                  </button>
                </div>
              </div>

              <!-- Opções Multiple Choice -->
              <div v-if="newForm.type === 'Multiple Choice'">
                <label
                  class="block text-xs font-bold text-text-secondary mb-1.5"
                >
                  Opções
                  <span class="font-normal opacity-60"
                    >(clica na letra para marcar como correta)</span
                  >
                </label>
                <div class="space-y-2">
                  <div
                    v-for="(opt, oIdx) in newForm.options"
                    :key="oIdx"
                    class="flex items-center gap-2"
                  >
                    <button
                      @click="newForm.correct = oIdx"
                      :class="
                        newForm.correct === oIdx
                          ? 'bg-success/20 border-success/40 text-success'
                          : 'bg-background border-white/10 text-text-secondary hover:border-white/20'
                      "
                      class="w-7 h-7 shrink-0 rounded-full border text-xs font-bold transition-all"
                    >
                      {{ String.fromCharCode(65 + oIdx) }}
                    </button>
                    <input
                      v-model="newForm.options[oIdx]"
                      class="flex-1 bg-background border border-white/10 rounded-btn px-3 py-1.5 text-sm text-white focus:outline-none focus:border-brand/50"
                      :placeholder="`Opção ${String.fromCharCode(65 + oIdx)}`"
                    />
                  </div>
                </div>
              </div>

              <!-- True/False -->
              <div v-if="newForm.type === 'True/False'">
                <label
                  class="block text-xs font-bold text-text-secondary mb-1.5"
                  >Resposta correta</label
                >
                <div class="flex gap-2">
                  <button
                    @click="newForm.correct = 'true'"
                    :class="
                      newForm.correct === 'true'
                        ? 'bg-success/20 text-success border-success/40'
                        : 'bg-background text-text-secondary border-white/10 hover:border-white/20'
                    "
                    class="flex-1 px-3 py-1.5 text-xs font-bold rounded-btn border transition-all"
                  >
                    Verdadeiro
                  </button>
                  <button
                    @click="newForm.correct = 'false'"
                    :class="
                      newForm.correct === 'false'
                        ? 'bg-error/20 text-error border-error/40'
                        : 'bg-background text-text-secondary border-white/10 hover:border-white/20'
                    "
                    class="flex-1 px-3 py-1.5 text-xs font-bold rounded-btn border transition-all"
                  >
                    Falso
                  </button>
                </div>
              </div>

              <div>
                <label
                  class="block text-xs font-bold text-text-secondary mb-1.5"
                  >Explicação (opcional)</label
                >
                <input
                  v-model="newForm.explanation"
                  class="w-full bg-background border border-white/10 rounded-btn px-3 py-2 text-sm text-white focus:outline-none focus:border-brand/50"
                  placeholder="Justificação da resposta correta..."
                />
              </div>
            </div>

            <div class="mt-6 flex justify-end gap-3">
              <button
                @click="closeAddModal"
                class="px-4 py-2 text-sm font-bold text-text-secondary border border-white/10 rounded-btn hover:text-white transition-all"
              >
                Cancelar
              </button>
              <button
                @click="createAndAddToPath"
                :disabled="!newForm.question.trim() || addingExercise"
                class="inline-flex items-center gap-2 px-5 py-2 text-sm font-bold bg-brand text-white rounded-btn hover:bg-brand/80 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <i
                  :class="
                    addingExercise ? 'pi pi-spinner pi-spin' : 'pi pi-check'
                  "
                  class="text-xs"
                ></i>
                {{ addingExercise ? 'A criar...' : 'Criar e Adicionar' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { usePathStore } from '../stores/pathStore';
import { useExerciseStore } from '../stores/exerciseStore';

const authStore = useAuthStore();
const pathStore = usePathStore();
const exerciseStore = useExerciseStore();

onMounted(async () => {
  await pathStore.loadPaths();
  if (pathStore.paths.length > 0) {
    selectedPathId.value = pathStore.paths[0].id_uc;
  }
});

// ─── Seleção ──────────────────────────────────────────────────────────────

const selectedPathId = ref(null);
const selectedCheckpointName = ref(null);

const selectedPath = computed(() =>
  pathStore.paths.find((p) => p.id_uc === selectedPathId.value),
);

const selectedCheckpoint = computed(() =>
  selectedPath.value?.checkpoints.find(
    (c) => c.topic_name === selectedCheckpointName.value,
  ),
);

function selectPath(idUc) {
  selectedPathId.value = idUc;
  selectedCheckpointName.value = null;
  cancelEdit();
}

// ─── Remover do percurso ──────────────────────────────────────────────────

const removingId = ref(null);

async function removeExercise(exerciseId) {
  if (removingId.value) return;
  removingId.value = exerciseId;
  try {
    await exerciseStore.updateExercise(exerciseId, { published: false });
    await pathStore.loadPaths(true);
    if (selectedCheckpoint.value?.exercises.length === 0) {
      selectedCheckpointName.value = null;
    }
  } finally {
    removingId.value = null;
  }
}

// ─── Edição inline ────────────────────────────────────────────────────────

const editingId = ref(null);
const savingEdit = ref(false);

const editForm = reactive({
  question: '',
  difficulty: 'Easy',
  explanation: '',
  options: [],
  correct: 0,
});

function startEdit(ex) {
  editingId.value = ex.id_exercise;
  editForm.question = ex.question;
  editForm.difficulty = ex.difficulty;
  editForm.explanation = ex.explanation || '';
  editForm.options = ex.solution?.options ? [...ex.solution.options] : [];

  const raw = ex.solution?.correct;
  if (ex.type === 'Multiple Choice') {
    if (typeof raw === 'string' && isNaN(Number(raw))) {
      editForm.correct = raw.toUpperCase().charCodeAt(0) - 65;
    } else {
      editForm.correct = raw !== null && raw !== undefined ? Number(raw) : 0;
    }
  } else {
    const s = String(raw ?? '').toLowerCase();
    editForm.correct = s === 'true' || s === 'verdadeiro' ? 'true' : 'false';
  }
}

function cancelEdit() {
  editingId.value = null;
  savingEdit.value = false;
}

async function saveEdit(exerciseId, type) {
  if (savingEdit.value) return;
  savingEdit.value = true;
  try {
    // Normalize correct to a letter so Flutter can parse it
    const rawCorrect = editForm.correct;
    const correctLetter =
      type === 'Multiple Choice'
        ? typeof rawCorrect === 'number'
          ? String.fromCharCode(65 + rawCorrect)
          : String(rawCorrect ?? 'A').toUpperCase()
        : rawCorrect; // True/False: keeps 'true'/'false'
    const solution =
      type === 'Multiple Choice'
        ? { options: [...editForm.options], correct: correctLetter }
        : { correct: correctLetter };

    await exerciseStore.updateExercise(exerciseId, {
      question: editForm.question,
      difficulty: editForm.difficulty,
      explanation: editForm.explanation,
      solution,
    });

    await pathStore.loadPaths(true);
    cancelEdit();
  } catch {
    // erro já no exerciseStore.error
  } finally {
    savingEdit.value = false;
  }
}

// ─── Modal: Adicionar Exercício ───────────────────────────────────────────

const showAddModal = ref(false);
const addTab = ref('existing');
const loadingDrafts = ref(false);
const addingExercise = ref(false);
const selectedDraftIds = ref([]);

// Exercícios em rascunho do tópico atual
const draftExercisesForTopic = computed(() => {
  if (!selectedCheckpoint.value || !exerciseStore.exercises.length) return [];
  return exerciseStore.exercises.filter(
    (ex) =>
      !ex.published &&
      ex.id_uc === selectedPathId.value &&
      ex.topic_name === selectedCheckpoint.value.topic_name,
  );
});

async function openAddModal() {
  selectedDraftIds.value = [];
  addTab.value = 'existing';
  loadingDrafts.value = true;
  showAddModal.value = true;
  // Carrega exercícios frescos para ter os rascunhos atualizados
  await exerciseStore.loadExercises(true);
  loadingDrafts.value = false;
}

function closeAddModal() {
  showAddModal.value = false;
  selectedDraftIds.value = [];
  resetNewForm();
}

function toggleSelectDraft(id) {
  const idx = selectedDraftIds.value.indexOf(id);
  if (idx === -1) {
    selectedDraftIds.value.push(id);
  } else {
    selectedDraftIds.value.splice(idx, 1);
  }
}

async function addExistingToPath() {
  if (!selectedDraftIds.value.length || addingExercise.value) return;
  addingExercise.value = true;
  try {
    // Publica cada exercício selecionado
    await Promise.all(
      selectedDraftIds.value.map((id) =>
        exerciseStore.updateExercise(id, { published: true }),
      ),
    );
    await pathStore.loadPaths(true);
    closeAddModal();
  } finally {
    addingExercise.value = false;
  }
}

// ─── Novo exercício ───────────────────────────────────────────────────────

const newForm = reactive({
  type: 'Multiple Choice',
  question: '',
  difficulty: 'Medium',
  explanation: '',
  options: ['', '', '', ''],
  correct: 0,
});

function resetNewFormAnswers() {
  if (newForm.type === 'Multiple Choice') {
    newForm.options = ['', '', '', ''];
    newForm.correct = 0;
  } else {
    newForm.correct = 'true';
  }
}

function resetNewForm() {
  newForm.type = 'Multiple Choice';
  newForm.question = '';
  newForm.difficulty = 'Medium';
  newForm.explanation = '';
  newForm.options = ['', '', '', ''];
  newForm.correct = 0;
}

async function createAndAddToPath() {
  if (!newForm.question.trim() || addingExercise.value) return;
  addingExercise.value = true;
  try {
    const solution =
      newForm.type === 'Multiple Choice'
        ? { options: [...newForm.options], correct: newForm.correct }
        : { correct: newForm.correct };

    await exerciseStore.addExercise({
      id_uc: selectedPathId.value,
      topic_name: selectedCheckpoint.value.topic_name,
      type: newForm.type,
      question: newForm.question,
      difficulty: newForm.difficulty,
      explanation: newForm.explanation,
      solution,
      published: true,
    });

    await pathStore.loadPaths(true);
    closeAddModal();
  } finally {
    addingExercise.value = false;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

const difficultyLabel = (d) =>
  ({ Easy: 'Fácil', Medium: 'Médio', Hard: 'Difícil' })[d] || d;

const typeLabel = (t) =>
  ({ 'Multiple Choice': 'Escolha Múltipla', 'True/False': 'V/F' })[t] || t;

function isMCCorrect(ex, oIdx) {
  const c = ex.solution?.correct;
  if (c === null || c === undefined) return false;
  if (typeof c === 'string' && isNaN(Number(c))) {
    return c.toUpperCase().charCodeAt(0) - 65 === oIdx;
  }
  return Number(c) === oIdx;
}

function isTrueFalseCorrect(ex, label) {
  const c = String(ex.solution?.correct ?? '').toLowerCase();
  const isTrue = c === 'true' || c === 'verdadeiro';
  return label === 'Verdadeiro' ? isTrue : !isTrue;
}
</script>
