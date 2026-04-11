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

    <!-- Conteúdo Original -->
    <template v-else>
      <div
        v-if="pathStore.isLoading"
        class="space-y-8 flex items-center justify-center py-20"
      >
        <div class="text-center">
          <i class="pi pi-spinner pi-spin text-brand text-4xl mb-4 block"></i>
          <p class="text-text-secondary">A carregar percursos...</p>
        </div>
      </div>
      <div class="space-y-8" v-else>
        <div class="flex justify-between items-end">
          <div>
            <p
              class="text-brand font-bold text-sm uppercase tracking-widest mb-1"
            >
              Caminho Base
            </p>
            <h3 class="text-3xl font-bold">Construtor de Percurso</h3>
            <p class="text-text-secondary mt-1">
              Defina o percurso de aprendizagem base que todos os alunos seguem.
            </p>
          </div>
        </div>

        <!-- Métricas -->
        <div class="grid grid-cols-4 gap-6">
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Percursos Criados</p>
            <p class="text-3xl font-bold mt-2">{{ pathStore.paths.length }}</p>
          </div>
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Publicados</p>
            <p class="text-3xl font-bold mt-2 text-success">
              {{ pathStore.publishedPaths.length }}
            </p>
          </div>
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Total Módulos</p>
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

        <!-- Seletor de disciplina -->
        <div class="flex items-center gap-3">
          <button
            v-for="p in pathStore.paths"
            :key="p.id"
            @click="selectedPathId = p.id"
            :class="
              selectedPathId === p.id
                ? 'bg-brand text-white'
                : 'bg-surface text-text-secondary border border-white/10'
            "
            class="px-6 py-3 rounded-chip text-sm font-bold transition-all flex items-center gap-2"
          >
            <span>{{ p.disciplineCode }}</span>
            <span class="text-xs opacity-70"
              >{{ p.modules.length }} módulos</span
            >
            <div
              class="w-2 h-2 rounded-full ml-1"
              :class="p.published ? 'bg-success' : 'bg-warning'"
            ></div>
          </button>
        </div>

        <!-- Path builder principal -->
        <div v-if="selectedPath" class="grid grid-cols-12 gap-6">
          <!-- Coluna esquerda: visualização do path (estilo Duolingo vertical) -->
          <div class="col-span-5">
            <div class="bg-surface rounded-card border border-white/5 p-6">
              <div class="flex items-center justify-between mb-6">
                <div>
                  <h4 class="text-lg font-bold">
                    {{ selectedPath.disciplineName }}
                  </h4>
                  <p class="text-text-secondary text-xs">
                    Última modificação: {{ selectedPath.lastModified }}
                  </p>
                </div>
                <div class="flex items-center gap-2">
                  <button
                    @click="pathStore.togglePathPublished(selectedPath.id)"
                    :class="
                      selectedPath.published
                        ? 'bg-success/10 text-success border-success/30'
                        : 'bg-warning/10 text-warning border-warning/30'
                    "
                    class="px-4 py-2 rounded-btn text-xs font-bold border transition-all"
                  >
                    <i
                      :class="
                        selectedPath.published
                          ? 'pi pi-check-circle'
                          : 'pi pi-clock'
                      "
                      class="mr-1"
                    ></i>
                    {{ selectedPath.published ? 'Publicado' : 'Rascunho' }}
                  </button>
                </div>
              </div>

              <!-- Visual path -->
              <div class="relative">
                <div
                  v-for="(mod, idx) in selectedPath.modules"
                  :key="mod.id"
                  class="relative"
                >
                  <!-- Connector -->
                  <div v-if="idx > 0" class="flex justify-center">
                    <div
                      class="w-0.5 h-8"
                      :class="
                        mod.status === 'published'
                          ? 'bg-brand/50'
                          : 'bg-gray-700'
                      "
                    ></div>
                  </div>

                  <!-- Module node -->
                  <div
                    @click="selectModule(mod)"
                    class="relative cursor-pointer group"
                    :class="{ 'ml-0': idx % 2 === 0, 'ml-12': idx % 2 !== 0 }"
                  >
                    <div
                      class="flex items-center gap-4 p-4 rounded-card border transition-all"
                      :class="
                        selectedModuleId === mod.id
                          ? 'bg-brand/10 border-brand shadow-lg shadow-brand/10'
                          : mod.status === 'published'
                            ? 'bg-background border-white/10 hover:border-brand/30'
                            : 'bg-background border-white/5 hover:border-warning/30 opacity-70'
                      "
                    >
                      <!-- Node circle -->
                      <div
                        class="w-14 h-14 rounded-full flex items-center justify-center text-xl font-bold shrink-0 shadow-lg"
                        :class="
                          mod.status === 'published'
                            ? 'bg-brand text-white'
                            : 'bg-gray-700 text-text-secondary'
                        "
                      >
                        {{ mod.order }}
                      </div>

                      <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-2 mb-1">
                          <p class="font-bold text-sm truncate">
                            {{ mod.title }}
                          </p>
                          <div
                            class="w-1.5 h-1.5 rounded-full shrink-0"
                            :class="
                              mod.status === 'published'
                                ? 'bg-success'
                                : 'bg-warning'
                            "
                          ></div>
                        </div>
                        <p class="text-text-secondary text-xs truncate">
                          {{ mod.exercises.length }} exercícios ·
                          {{ mod.xpReward }} XP
                        </p>
                      </div>

                      <!-- Reorder buttons -->
                      <div
                        class="flex flex-col gap-1 opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <button
                          v-if="idx > 0"
                          @click.stop="
                            pathStore.moveModuleUp(selectedPath.id, mod.id)
                          "
                          class="text-text-secondary hover:text-brand text-xs"
                        >
                          <i class="pi pi-chevron-up"></i>
                        </button>
                        <button
                          v-if="idx < selectedPath.modules.length - 1"
                          @click.stop="
                            pathStore.moveModuleDown(selectedPath.id, mod.id)
                          "
                          class="text-text-secondary hover:text-brand text-xs"
                        >
                          <i class="pi pi-chevron-down"></i>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Add module button -->
                <div class="flex justify-center mt-4">
                  <div class="w-0.5 h-6 bg-gray-700"></div>
                </div>
                <div class="flex justify-center">
                  <button
                    @click="showAddModule = true"
                    class="w-14 h-14 rounded-full border-2 border-dashed border-white/20 flex items-center justify-center text-text-secondary hover:border-brand hover:text-brand transition-all"
                  >
                    <i class="pi pi-plus text-lg"></i>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Coluna direita: detalhes do módulo selecionado -->
          <div class="col-span-7 space-y-4">
            <div
              v-if="!selectedModule"
              class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center"
            >
              <i class="pi pi-arrow-left text-4xl text-brand/30 mb-4 block"></i>
              <p class="text-text-secondary">
                Selecione um módulo à esquerda para ver e editar os seus
                exercícios.
              </p>
            </div>

            <template v-else>
              <!-- Module header -->
              <div class="bg-surface rounded-card border border-white/5 p-6">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="flex items-center gap-3 mb-2">
                      <span
                        class="bg-brand/10 text-brand text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                      >
                        Módulo {{ selectedModule.order }}
                      </span>
                      <span
                        class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                        :class="
                          selectedModule.status === 'published'
                            ? 'bg-success/10 text-success'
                            : 'bg-warning/10 text-warning'
                        "
                      >
                        {{
                          selectedModule.status === 'published'
                            ? 'Publicado'
                            : 'Rascunho'
                        }}
                      </span>
                    </div>
                    <h4 class="text-xl font-bold">
                      {{ selectedModule.title }}
                    </h4>
                    <p class="text-text-secondary text-sm mt-1">
                      {{ selectedModule.description }}
                    </p>
                    <div
                      class="flex items-center gap-4 mt-3 text-xs text-text-secondary"
                    >
                      <span
                        ><i class="pi pi-bolt text-warning mr-1"></i
                        >{{ selectedModule.xpReward }} XP</span
                      >
                      <span
                        ><i class="pi pi-list text-brand mr-1"></i
                        >{{ selectedModule.exercises.length }} exercícios</span
                      >
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <button
                      @click="openEditModule"
                      class="text-text-secondary hover:text-white transition-colors p-2"
                      title="Editar módulo"
                    >
                      <i class="pi pi-pencil"></i>
                    </button>
                    <button
                      @click="
                        pathStore.toggleModuleStatus(
                          selectedPath.id,
                          selectedModule.id,
                        )
                      "
                      class="text-text-secondary hover:text-success transition-colors p-2"
                      :title="
                        selectedModule.status === 'published'
                          ? 'Despublicar'
                          : 'Publicar'
                      "
                    >
                      <i
                        :class="
                          selectedModule.status === 'published'
                            ? 'pi pi-eye-slash'
                            : 'pi pi-eye'
                        "
                      ></i>
                    </button>
                    <button
                      @click="
                        pathStore.removeModule(
                          selectedPath.id,
                          selectedModule.id,
                        );
                        selectedModuleId = null;
                      "
                      class="text-text-secondary hover:text-error transition-colors p-2"
                      title="Remover módulo"
                    >
                      <i class="pi pi-trash"></i>
                    </button>
                  </div>
                </div>
              </div>

              <!-- Exercícios do módulo -->
              <div class="flex items-center justify-between">
                <h5
                  class="font-bold text-sm text-text-secondary uppercase tracking-widest"
                >
                  Exercícios do Módulo
                </h5>
                <button
                  @click="openAddExercise"
                  class="bg-brand text-white px-4 py-2 rounded-btn text-sm font-bold hover:brightness-110 transition-all flex items-center gap-2"
                >
                  <i class="pi pi-plus text-xs"></i> Adicionar Exercício
                </button>
              </div>

              <div
                v-if="selectedModule.exercises.length === 0"
                class="bg-surface rounded-card border border-white/5 border-dashed p-8 text-center"
              >
                <p class="text-text-secondary text-sm">
                  Sem exercícios neste módulo. Adicione exercícios manualmente
                  ou use o
                  <router-link to="/generator" class="text-brand underline"
                    >Gerador IA</router-link
                  >.
                </p>
              </div>

              <div
                v-for="(ex, eIdx) in selectedModule.exercises"
                :key="ex.id"
                class="bg-surface rounded-card border border-white/5 p-5 group relative"
              >
                <!-- Actions hover -->
                <div
                  class="absolute right-4 top-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <button
                    @click="openEditExercise(ex)"
                    class="text-text-secondary hover:text-brand"
                    title="Editar"
                  >
                    <i class="pi pi-pencil text-sm"></i>
                  </button>
                  <button
                    @click="
                      pathStore.removeExerciseFromModule(
                        selectedPath.id,
                        selectedModule.id,
                        ex.id,
                      )
                    "
                    class="text-text-secondary hover:text-error"
                    title="Remover"
                  >
                    <i class="pi pi-trash text-sm"></i>
                  </button>
                </div>

                <div class="flex items-center gap-2 mb-3">
                  <span class="text-brand text-xs font-bold"
                    >Q{{ eIdx + 1 }}</span
                  >
                  <span
                    class="text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-chip"
                    :class="
                      ex.difficulty === 'Fácil'
                        ? 'bg-success/10 text-success'
                        : ex.difficulty === 'Médio'
                          ? 'bg-warning/10 text-warning'
                          : 'bg-error/10 text-error'
                    "
                  >
                    {{ ex.difficulty }}
                  </span>
                  <span
                    class="text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-chip bg-brand/10 text-brand"
                  >
                    {{ typeLabel(ex.type) }}
                  </span>
                </div>
                <p class="font-medium text-sm mb-3">{{ ex.title }}</p>
                <!-- Multiple Choice / True-False -->
                <div
                  v-if="ex.type === 'multipleChoice' || ex.type === 'trueFalse'"
                  class="grid grid-cols-2 gap-2"
                >
                  <div
                    v-for="(opt, oIdx) in ex.options"
                    :key="oIdx"
                    class="text-xs p-2.5 rounded-btn border"
                    :class="
                      oIdx === ex.correct
                        ? 'bg-success/10 border-success/30 text-success'
                        : 'bg-background border-white/5 text-text-secondary'
                    "
                  >
                    <span class="font-bold mr-2">{{
                      ex.type === 'trueFalse'
                        ? oIdx === 0
                          ? 'V'
                          : 'F'
                        : String.fromCharCode(65 + oIdx)
                    }}</span
                    >{{ opt }}
                  </div>
                </div>

                <!-- Solution/Explanation preview -->
                <div
                  v-if="ex.solution || ex.explanation"
                  class="mt-2 text-xs text-text-secondary truncate"
                >
                  <i class="pi pi-info-circle mr-1"></i
                  >{{ ex.explanation || ex.solution }}
                </div>
              </div>
            </template>
          </div>
        </div>

        <!-- Modal: Adicionar Módulo -->
        <Teleport to="body">
          <div
            v-if="showAddModule"
            class="fixed inset-0 z-50 flex items-center justify-center"
          >
            <div
              class="absolute inset-0 bg-black/60 backdrop-blur-sm"
              @click="showAddModule = false"
            ></div>
            <div
              class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-8 shadow-2xl z-10"
            >
              <h4 class="text-xl font-bold mb-6">
                {{ editingModule ? 'Editar Módulo' : 'Adicionar Módulo' }}
              </h4>
              <div class="space-y-4">
                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                    >Título do Módulo</label
                  >
                  <input
                    v-model="moduleForm.title"
                    type="text"
                    placeholder="Ex: Flip-Flops e Contadores"
                    class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                  />
                </div>
                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                    >Descrição</label
                  >
                  <textarea
                    v-model="moduleForm.description"
                    rows="3"
                    placeholder="Breve descrição do conteúdo deste módulo..."
                    class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
                  ></textarea>
                </div>
                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                    >Recompensa XP</label
                  >
                  <input
                    v-model.number="moduleForm.xpReward"
                    type="number"
                    min="10"
                    max="500"
                    class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                  />
                </div>
              </div>
              <div class="flex justify-end gap-3 mt-8">
                <button
                  @click="showAddModule = false"
                  class="px-6 py-3 rounded-btn text-text-secondary hover:text-white border border-white/10 text-sm font-bold transition-all"
                >
                  Cancelar
                </button>
                <button
                  @click="saveModule"
                  class="bg-brand px-6 py-3 rounded-btn text-white font-bold hover:brightness-110 transition-all text-sm"
                >
                  {{ editingModule ? 'Guardar' : 'Adicionar' }}
                </button>
              </div>
            </div>
          </div>
        </Teleport>

        <!-- Modal: Adicionar/Editar Exercício -->
        <Teleport to="body">
          <div
            v-if="showExerciseModal"
            class="fixed inset-0 z-50 flex items-center justify-center"
          >
            <div
              class="absolute inset-0 bg-black/60 backdrop-blur-sm"
              @click="showExerciseModal = false"
            ></div>
            <div
              class="relative bg-surface border border-white/10 rounded-card w-full max-w-2xl p-8 shadow-2xl z-10 max-h-[85vh] overflow-y-auto"
            >
              <h4 class="text-xl font-bold mb-6">
                {{
                  editingExerciseId ? 'Editar Exercício' : 'Adicionar Exercício'
                }}
              </h4>
              <div class="space-y-4">
                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block"
                    >Tipo de Exercício</label
                  >
                  <div class="flex gap-2 flex-wrap">
                    <button
                      v-for="t in exerciseTypes"
                      :key="t.value"
                      @click="changeExerciseType(t.value)"
                      :class="
                        exerciseForm.type === t.value
                          ? 'bg-brand text-white'
                          : 'bg-background text-text-secondary border border-white/10'
                      "
                      class="px-4 py-2 rounded-chip text-xs font-bold transition-all"
                    >
                      {{ t.label }}
                    </button>
                  </div>
                </div>
                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                    >Pergunta</label
                  >
                  <textarea
                    v-model="exerciseForm.title"
                    rows="2"
                    placeholder="Escreva a pergunta..."
                    class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
                  ></textarea>
                </div>
                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block"
                    >Dificuldade</label
                  >
                  <div class="flex gap-2">
                    <button
                      v-for="d in ['Fácil', 'Médio', 'Difícil']"
                      :key="d"
                      @click="exerciseForm.difficulty = d"
                      :class="
                        exerciseForm.difficulty === d
                          ? 'bg-brand text-white'
                          : 'bg-background text-text-secondary border border-white/10'
                      "
                      class="px-4 py-2 rounded-chip text-xs font-bold transition-all"
                    >
                      {{ d }}
                    </button>
                  </div>
                </div>
                <!-- Multiple Choice options -->
                <div v-if="exerciseForm.type === 'multipleChoice'">
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block"
                  >
                    Opções
                    <span class="text-text-secondary font-normal"
                      >(clique no rádio para marcar a correta)</span
                    >
                  </label>
                  <div class="space-y-2">
                    <div
                      v-for="(opt, oIdx) in exerciseForm.options"
                      :key="oIdx"
                      class="flex items-center gap-3"
                    >
                      <button
                        @click="exerciseForm.correct = oIdx"
                        class="w-6 h-6 rounded-full border-2 flex items-center justify-center shrink-0 transition-all"
                        :class="
                          exerciseForm.correct === oIdx
                            ? 'border-success bg-success'
                            : 'border-white/20'
                        "
                      >
                        <i
                          v-if="exerciseForm.correct === oIdx"
                          class="pi pi-check text-[10px] text-black"
                        ></i>
                      </button>
                      <input
                        v-model="exerciseForm.options[oIdx]"
                        :placeholder="'Opção ' + String.fromCharCode(65 + oIdx)"
                        class="flex-1 bg-background p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                      />
                    </div>
                  </div>
                </div>
                <!-- True/False options -->
                <div v-if="exerciseForm.type === 'trueFalse'">
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block"
                    >Resposta Correta</label
                  >
                  <div class="flex gap-3">
                    <button
                      @click="exerciseForm.correct = 0"
                      :class="
                        exerciseForm.correct === 0
                          ? 'bg-success text-black'
                          : 'bg-background text-text-secondary border border-white/10'
                      "
                      class="flex-1 py-3 rounded-btn text-sm font-bold transition-all"
                    >
                      Verdadeiro
                    </button>
                    <button
                      @click="exerciseForm.correct = 1"
                      :class="
                        exerciseForm.correct === 1
                          ? 'bg-error text-white'
                          : 'bg-background text-text-secondary border border-white/10'
                      "
                      class="flex-1 py-3 rounded-btn text-sm font-bold transition-all"
                    >
                      Falso
                    </button>
                  </div>
                </div>

                <!-- Solution and Explanation (all types) -->
                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                    >Solução</label
                  >
                  <input
                    v-model="exerciseForm.solution"
                    type="text"
                    placeholder="Resposta resumida..."
                    class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                  />
                </div>
                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                    >Explicação</label
                  >
                  <textarea
                    v-model="exerciseForm.explanation"
                    rows="2"
                    placeholder="Porquê esta resposta..."
                    class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
                  ></textarea>
                </div>
              </div>
              <div class="flex justify-end gap-3 mt-8">
                <button
                  @click="showExerciseModal = false"
                  class="px-6 py-3 rounded-btn text-text-secondary hover:text-white border border-white/10 text-sm font-bold transition-all"
                >
                  Cancelar
                </button>
                <button
                  @click="saveExercise"
                  class="bg-brand px-6 py-3 rounded-btn text-white font-bold hover:brightness-110 transition-all text-sm"
                >
                  {{ editingExerciseId ? 'Guardar' : 'Adicionar' }}
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
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { usePathStore } from '../stores/pathStore';

const authStore = useAuthStore();
const pathStore = usePathStore();

onMounted(async () => {
  await pathStore.loadPaths();
});

const selectedPathId = ref(null);
const selectedModuleId = ref(null);

// Atualizar selectedPathId quando os dados chegam
watch(
  () => pathStore.paths,
  (newPaths) => {
    if (newPaths.length > 0 && !selectedPathId.value) {
      selectedPathId.value = newPaths[0].id;
    }
  },
  { immediate: true },
);

const selectedPath = computed(() =>
  pathStore.paths.find((p) => p.id === selectedPathId.value),
);
const selectedModule = computed(() =>
  selectedPath.value?.modules.find((m) => m.id === selectedModuleId.value),
);

function selectModule(mod) {
  selectedModuleId.value = mod.id;
}

// ── Module modal ──
const showAddModule = ref(false);
const editingModule = ref(false);
const moduleForm = reactive({ title: '', description: '', xpReward: 75 });

function openEditModule() {
  if (!selectedModule.value) return;
  editingModule.value = true;
  moduleForm.title = selectedModule.value.title;
  moduleForm.description = selectedModule.value.description;
  moduleForm.xpReward = selectedModule.value.xpReward;
  showAddModule.value = true;
}

function saveModule() {
  if (editingModule.value && selectedModule.value) {
    pathStore.updateModule(selectedPath.value.id, selectedModule.value.id, {
      title: moduleForm.title,
      description: moduleForm.description,
      xpReward: moduleForm.xpReward,
    });
  } else {
    const id =
      selectedPath.value.disciplineCode.toLowerCase() +
      '-m' +
      (selectedPath.value.modules.length + 1) +
      '-' +
      Date.now();
    pathStore.addModule(selectedPath.value.id, {
      id,
      title: moduleForm.title,
      description: moduleForm.description,
      xpReward: moduleForm.xpReward,
    });
  }
  showAddModule.value = false;
  editingModule.value = false;
  moduleForm.title = '';
  moduleForm.description = '';
  moduleForm.xpReward = 75;
}

// ── Exercise modal ──
const showExerciseModal = ref(false);
const editingExerciseId = ref(null);
const exerciseForm = reactive({
  type: 'multipleChoice',
  title: '',
  options: ['', '', '', ''],
  correct: 0,
  difficulty: 'Médio',
  solution: '',
  explanation: '',
});

const exerciseTypes = [
  { value: 'multipleChoice', label: 'Escolha Múltipla' },
  { value: 'trueFalse', label: 'Verdadeiro / Falso' },
];

function typeLabel(type) {
  const t = exerciseTypes.find((et) => et.value === type);
  return t ? t.label : type || 'Escolha Múltipla';
}

function changeExerciseType(type) {
  exerciseForm.type = type;
  if (type === 'trueFalse') {
    exerciseForm.options = ['Verdadeiro', 'Falso'];
    exerciseForm.correct = 0;
  } else if (type === 'multipleChoice') {
    if (exerciseForm.options.length !== 4)
      exerciseForm.options = ['', '', '', ''];
    exerciseForm.correct = 0;
  }
}

function openAddExercise() {
  editingExerciseId.value = null;
  exerciseForm.type = 'multipleChoice';
  exerciseForm.title = '';
  exerciseForm.options = ['', '', '', ''];
  exerciseForm.correct = 0;
  exerciseForm.difficulty = 'Médio';
  exerciseForm.solution = '';
  exerciseForm.explanation = '';
  showExerciseModal.value = true;
}

function openEditExercise(ex) {
  editingExerciseId.value = ex.id;
  exerciseForm.type = ex.type || 'multipleChoice';
  exerciseForm.title = ex.title;
  exerciseForm.options = ex.options ? [...ex.options] : ['', '', '', ''];
  exerciseForm.correct = ex.correct ?? 0;
  exerciseForm.difficulty = ex.difficulty;
  exerciseForm.solution = ex.solution || '';
  exerciseForm.explanation = ex.explanation || '';
  showExerciseModal.value = true;
}

function saveExercise() {
  const data = {
    type: exerciseForm.type,
    title: exerciseForm.title,
    difficulty: exerciseForm.difficulty,
    solution: exerciseForm.solution,
    explanation: exerciseForm.explanation,
  };
  if (exerciseForm.type === 'multipleChoice') {
    data.options = [...exerciseForm.options];
    data.correct = exerciseForm.correct;
  } else if (exerciseForm.type === 'trueFalse') {
    data.options = ['Verdadeiro', 'Falso'];
    data.correct = exerciseForm.correct;
  }
  if (editingExerciseId.value) {
    pathStore.updateExerciseInModule(
      selectedPath.value.id,
      selectedModule.value.id,
      editingExerciseId.value,
      data,
    );
  } else {
    const id =
      selectedModule.value.id +
      '-e' +
      (selectedModule.value.exercises.length + 1) +
      '-' +
      Date.now();
    pathStore.addExerciseToModule(
      selectedPath.value.id,
      selectedModule.value.id,
      { id, ...data },
    );
  }
  showExerciseModal.value = false;
}
</script>
