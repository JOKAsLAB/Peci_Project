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
        v-if="exerciseStore.isLoading"
        class="space-y-8 flex items-center justify-center py-20"
      >
        <div class="text-center">
          <i class="pi pi-spinner pi-spin text-brand text-4xl mb-4 block"></i>
          <p class="text-text-secondary">A carregar exercícios...</p>
        </div>
      </div>
      <div class="space-y-8" v-else>
        <div class="flex justify-between items-end">
          <div>
            <p
              class="text-brand font-bold text-sm uppercase tracking-widest mb-1"
            >
              Banco de Exercícios
            </p>
            <h3 class="text-3xl font-bold">Gestão de Exercícios</h3>
            <p class="text-text-secondary mt-1">
              Consulte, filtre e edite todo o banco de questões.
            </p>
          </div>
        </div>

        <div
          v-if="exerciseStore.error"
          class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
        >
          <i class="pi pi-exclamation-triangle mr-2"></i>
          {{ exerciseStore.error }}
        </div>

        <div class="grid grid-cols-4 gap-6">
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Total Exercícios</p>
            <p class="text-3xl font-bold mt-2">
              {{ filteredExercises.length }}
            </p>
          </div>
          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Publicados</p>
            <p class="text-3xl font-bold mt-2 text-success">
              {{ filteredExercises.filter((e) => e.published).length }}
            </p>
          </div>

          <div class="bg-surface p-6 rounded-card border border-white/5">
            <p class="text-text-secondary text-sm">Disciplinas Atribuídas</p>
            <p class="text-3xl font-bold mt-2 text-brand">
              {{ authStore.user?.course_units?.length || 0 }}
            </p>
          </div>
        </div>

        <div class="bg-surface rounded-card border border-white/5 p-6">
          <h4
            class="text-sm font-bold text-text-secondary uppercase tracking-widest mb-4"
          >
            Filtros
          </h4>
          <div class="flex flex-wrap items-center gap-4">
            <div class="flex items-center gap-2">
              <button
                v-for="f in ['Todos', 'Publicados']"
                :key="f"
                @click="statusFilter = f"
                :class="
                  statusFilter === f
                    ? 'bg-brand text-white'
                    : 'bg-background text-text-secondary border border-white/10'
                "
                class="px-4 py-2 rounded-chip text-xs font-bold transition-all"
              >
                {{ f }}
              </button>
            </div>

            <div class="w-px h-8 bg-white/10"></div>

            <div class="flex items-center gap-2">
              <span class="text-text-secondary text-xs font-bold uppercase"
                >Disciplina:</span
              >
              <select
                v-model="disciplineFilter"
                class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand"
              >
                <option value="">Todas</option>
                <option
                  v-for="uc in authStore.user?.course_units || []"
                  :key="uc.id"
                  :value="uc.id"
                >
                  {{ uc.name }}
                </option>
              </select>
            </div>

            <div class="flex items-center gap-2">
              <span class="text-text-secondary text-xs font-bold uppercase"
                >Módulo:</span
              >
              <select
                v-model="moduleFilter"
                class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand min-w-[180px]"
              >
                <option value="">Todos</option>
                <option v-for="m in availableModules" :key="m" :value="m">
                  {{ m }}
                </option>
              </select>
            </div>

            <div class="flex items-center gap-2">
              <span class="text-text-secondary text-xs font-bold uppercase"
                >Dificuldade:</span
              >
              <select
                v-model="difficultyFilter"
                class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand"
              >
                <option value="">Todas</option>
                <option value="Fácil">Fácil</option>
                <option value="Médio">Médio</option>
                <option value="Difícil">Difícil</option>
              </select>
            </div>

            <div class="flex items-center gap-2">
              <span class="text-text-secondary text-xs font-bold uppercase"
                >Tipo:</span
              >
              <select
                v-model="typeFilter"
                class="bg-background border border-white/10 px-3 py-2 rounded-btn text-xs outline-none focus:border-brand"
              >
                <option value="">Todos</option>
                <option value="multipleChoice">Escolha Múltipla</option>
                <option value="trueFalse">V/F</option>
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

        <div
          class="bg-surface rounded-card border border-white/5 overflow-hidden relative"
        >
          <div
            v-if="exerciseStore.isLoading"
            class="absolute inset-0 bg-black/40 backdrop-blur-sm z-20 flex items-center justify-center"
          >
            <i class="pi pi-spinner pi-spin text-brand text-3xl"></i>
          </div>

          <table class="w-full text-left">
            <thead
              class="bg-black/20 text-text-secondary uppercase text-[10px] tracking-widest"
            >
              <tr>
                <th class="px-6 py-4 font-semibold w-8">#</th>
                <th class="px-6 py-4 font-semibold">Exercício</th>
                <th class="px-6 py-4 font-semibold text-center">Tipo</th>
                <th class="px-6 py-4 font-semibold text-center">Disciplina</th>
                <th class="px-6 py-4 font-semibold text-center">Módulo</th>
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
                <td class="px-6 py-4 max-w-xs">
                  <p class="font-medium text-sm truncate" :title="ex.title">
                    {{ ex.title }}
                  </p>
                </td>
                <td class="px-6 py-4 text-center">
                  <span
                    class="text-xs font-bold px-3 py-1 rounded-chip"
                    :class="typeClass(ex.type)"
                  >
                    {{ typeLabel(ex.type) }}
                  </span>
                </td>
                <td class="px-6 py-4 text-center">
                  <span
                    class="bg-brand/10 text-brand text-xs font-bold px-3 py-1 rounded-chip"
                    >{{ ex.discipline }}</span
                  >
                </td>
                <td
                  class="px-6 py-4 text-center text-text-secondary text-xs max-w-[160px] truncate"
                  :title="ex.module"
                >
                  {{ ex.module }}
                </td>
                <td class="px-6 py-4 text-center">
                  <span
                    class="text-xs font-bold px-3 py-1 rounded-chip"
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
                </td>
                <td class="px-6 py-4 text-center">
                  <div
                    @click="togglePublished(ex.id)"
                    class="cursor-pointer flex items-center justify-center gap-2"
                    :class="{
                      'opacity-50 pointer-events-none': exerciseStore.isLoading,
                    }"
                  >
                    <div
                      class="w-2 h-2 rounded-full"
                      :class="ex.published ? 'bg-success' : 'bg-warning'"
                    ></div>
                    <span class="text-xs">{{ 'Publicado' }}</span>
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

        <Teleport to="body">
          <div
            v-if="detailExercise"
            class="fixed inset-0 z-50 flex items-center justify-center"
          >
            <div
              class="absolute inset-0 bg-black/60 backdrop-blur-sm"
              @click="detailExercise = null"
            ></div>
            <div
              class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-8 shadow-2xl z-10"
            >
              <div class="flex justify-between items-center mb-4">
                <div class="flex items-center gap-2">
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
                      detailExercise.difficulty === 'Fácil'
                        ? 'bg-success/10 text-success'
                        : detailExercise.difficulty === 'Médio'
                          ? 'bg-warning/10 text-warning'
                          : 'bg-error/10 text-error'
                    "
                  >
                    {{ detailExercise.difficulty }}
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
                {{ detailExercise.module }}
              </p>
              <h4 class="font-bold mb-4">{{ detailExercise.title }}</h4>
              <div class="space-y-2 mb-4">
                <div
                  v-for="(opt, i) in detailExercise.options"
                  :key="i"
                  class="flex items-center gap-3 p-3 rounded-btn border text-sm"
                  :class="
                    i === detailExercise.correct
                      ? 'border-success/30 bg-success/5 text-success'
                      : 'border-white/5 bg-background text-text-secondary'
                  "
                >
                  <span
                    class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold"
                    :class="
                      i === detailExercise.correct
                        ? 'bg-success/20'
                        : 'bg-white/5'
                    "
                    >{{ String.fromCharCode(65 + i) }}</span
                  >
                  {{ opt }}
                </div>
              </div>
              <div class="bg-background p-4 rounded-btn border border-white/5">
                <p
                  class="text-xs font-bold text-brand uppercase tracking-widest mb-1"
                >
                  Explicação
                </p>
                <p class="text-sm text-text-secondary">
                  {{ detailExercise.explanation }}
                </p>
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

const userDisciplineIds = computed(() => {
  try {
    const ids = authStore.user?.course_units?.map((uc) => uc.id) || [];
    console.log('📚 User discipline IDs:', ids);
    return ids;
  } catch (e) {
    console.error('❌ Error getting user disciplines:', e);
    return [];
  }
});

const statusFilter = ref('Todos');
const disciplineFilter = ref('');
const moduleFilter = ref('');
const difficultyFilter = ref('');
const typeFilter = ref('');
const currentPage = ref(1);
const pageSize = 15;
const detailExercise = ref(null);

const availableModules = computed(() => {
  try {
    if (
      disciplineFilter.value &&
      exerciseStore.modulesByDiscipline &&
      exerciseStore.modulesByDiscipline[disciplineFilter.value]
    ) {
      return exerciseStore.modulesByDiscipline[disciplineFilter.value] || [];
    }
    return exerciseStore.modules || [];
  } catch (e) {
    console.error('❌ Error getting modules:', e);
    return [];
  }
});

watch(disciplineFilter, () => {
  moduleFilter.value = '';
  currentPage.value = 1;
});
watch([statusFilter, moduleFilter, difficultyFilter, typeFilter], () => {
  currentPage.value = 1;
});

const hasActiveFilters = computed(() => {
  try {
    return (
      statusFilter.value !== 'Todos' ||
      !!disciplineFilter.value ||
      !!moduleFilter.value ||
      !!difficultyFilter.value ||
      !!typeFilter.value
    );
  } catch (e) {
    return false;
  }
});

function clearFilters() {
  statusFilter.value = 'Todos';
  disciplineFilter.value = '';
  moduleFilter.value = '';
  difficultyFilter.value = '';
  typeFilter.value = '';
}

const filteredExercises = computed(() => {
  try {
    let list = Array.isArray(exerciseStore.exercises) ? [...exerciseStore.exercises] : [];
    console.log('🔍 Filtering exercises, total:', list.length);
    
    // Filtrar apenas exercícios das disciplinas atribuídas
    const userIds = userDisciplineIds.value || [];
    if (userIds.length > 0) {
      list = list.filter((e) => userIds.includes(e?.id_uc));
    }
    
    if (statusFilter.value === 'Publicados') {
      list = list.filter((e) => e?.published === true);
    }
    if (disciplineFilter.value) {
      list = list.filter((e) => e?.id_uc === disciplineFilter.value);
    }
    if (moduleFilter.value) {
      list = list.filter((e) => e?.module === moduleFilter.value);
    }
    if (difficultyFilter.value) {
      list = list.filter((e) => e?.difficulty === difficultyFilter.value);
    }
    if (typeFilter.value) {
      list = list.filter((e) => e?.type === typeFilter.value);
    }
    
    console.log('✓ Filtered result:', list.length);
    return list;
  } catch (e) {
    console.error('❌ Error filtering exercises:', e);
    return [];
  }
});

const totalPages = computed(() => {
  try {
    return Math.max(1, Math.ceil(filteredExercises.value.length / pageSize));
  } catch (e) {
    console.error('❌ Error calculating total pages:', e);
    return 1;
  }
});

const paginatedExercises = computed(() => {
  try {
    const start = (currentPage.value - 1) * pageSize;
    return filteredExercises.value.slice(start, start + pageSize);
  } catch (e) {
    console.error('❌ Error paginating exercises:', e);
    return [];
  }
});

function showDetail(ex) {
  detailExercise.value = ex;
}

// Funções transacionais locais que interceptam as chamadas à store
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

const typeLabels = { multipleChoice: 'Escolha Múltipla', trueFalse: 'V/F' };
const typeLabel = (type) => typeLabels[type] || 'Escolha Múltipla';
const typeClass = (type) =>
  ({
    multipleChoice: 'bg-brand/10 text-brand',
    trueFalse: 'bg-purple-500/10 text-purple-400',
  })[type] || 'bg-brand/10 text-brand';
</script>
