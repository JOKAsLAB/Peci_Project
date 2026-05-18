<template>
  <Teleport to="body">
    <div
      v-if="modelValue"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm"
      @click.self="close"
    >
      <div class="bg-surface border border-white/10 rounded-card w-full max-w-md shadow-2xl flex flex-col max-h-[90vh]">

        <!-- Close button -->
        <div class="flex justify-end px-4 pt-4 shrink-0">
          <button @click="close" class="text-text-secondary hover:text-white transition-colors p-1">
            <i class="pi pi-times text-base"></i>
          </button>
        </div>

        <!-- Content -->
        <div class="overflow-y-auto flex-1 px-4 sm:px-6 pb-4">

          <!-- Página 1: Andy -->
          <template v-if="active === 0">
            <div class="flex flex-col items-center text-center">
              <div class="w-24 h-24 rounded-2xl border border-brand/40 bg-background flex items-center justify-center mb-5">
                <img src="/chatbot.png" alt="Andy" class="w-16 h-16 object-contain" />
              </div>
              <h2 class="text-xl font-bold mb-2">Olá! Sou o Andy 👋</h2>
              <p class="text-text-secondary text-sm leading-relaxed mb-6">
                A plataforma de estudo para Sistemas Digitais.<br />Vê como funciona em 3 passos rápidos.
              </p>
              <div class="flex justify-center gap-6">
                <div v-for="s in sections" :key="s.label" class="flex flex-col items-center gap-1.5">
                  <i :class="s.icon" class="text-brand text-xl"></i>
                  <span class="text-text-secondary text-xs">{{ s.label }}</span>
                </div>
              </div>
              <p class="text-text-secondary text-xs mt-5">
                Navega entre as secções usando a barra lateral.
              </p>
            </div>
          </template>

          <!-- Página 2: Percursos e Prática -->
          <template v-else-if="active === 1">
            <div class="flex flex-col items-center text-center mb-5">
              <div class="w-14 h-14 rounded-full bg-brand/10 flex items-center justify-center mb-4">
                <i class="pi pi-book text-brand text-2xl"></i>
              </div>
              <h2 class="text-xl font-bold">Percursos e Prática</h2>
            </div>
            <div class="space-y-4">
              <div v-for="rule in courseRules" :key="rule.title" class="flex gap-3">
                <div class="w-8 h-8 rounded-full flex items-center justify-center shrink-0 mt-0.5" :style="{ background: rule.bg }">
                  <i :class="rule.icon" class="text-sm" :style="{ color: rule.color }"></i>
                </div>
                <div>
                  <p class="font-semibold text-sm mb-0.5">{{ rule.title }}</p>
                  <p class="text-text-secondary text-sm leading-relaxed">{{ rule.desc }}</p>
                </div>
              </div>
            </div>
          </template>

          <!-- Página 3: XP, Streak e Nível -->
          <template v-else-if="active === 2">
            <div class="flex flex-col items-center text-center mb-5">
              <div class="w-14 h-14 rounded-full flex items-center justify-center mb-4" style="background: rgba(251,146,60,0.12)">
                <span class="text-2xl">🔥</span>
              </div>
              <h2 class="text-xl font-bold">XP, Streak e Nível</h2>
            </div>
            <div class="space-y-4">
              <div class="flex gap-3">
                <div class="w-8 h-8 rounded-full flex items-center justify-center shrink-0 mt-0.5" style="background: rgba(251,146,60,0.12)">
                  <span class="text-sm">🔥</span>
                </div>
                <div class="flex-1">
                  <p class="font-semibold text-sm mb-0.5">5 exercícios diários = Bónus XP</p>
                  <p class="text-text-secondary text-sm leading-relaxed mb-3">Os primeiros 5 por dia têm 1.5× XP e mantêm o streak. Depois continuas com XP normal:</p>
                  <div class="bg-background rounded-btn border border-white/5 p-3 space-y-2">
                    <div v-for="row in xpTable" :key="row.diff" class="flex items-center gap-2">
                      <span class="px-2 py-0.5 rounded text-xs font-semibold min-w-[52px] text-center" :class="row.cls">{{ row.diff }}</span>
                      <span class="text-text-secondary text-xs w-12 text-right">{{ row.base }} XP</span>
                      <i class="pi pi-arrow-right text-text-secondary text-xs mx-auto"></i>
                      <span class="font-bold text-brand text-xs w-12 text-right">{{ row.bonus }} XP</span>
                    </div>
                  </div>
                </div>
              </div>
              <div class="flex gap-3">
                <div class="w-8 h-8 rounded-full flex items-center justify-center shrink-0 mt-0.5" style="background: rgba(255,213,79,0.12)">
                  <i class="pi pi-trophy text-sm" style="color: #ffd54f"></i>
                </div>
                <div>
                  <p class="font-semibold text-sm mb-0.5">Nível e estatísticas</p>
                  <p class="text-text-secondary text-sm leading-relaxed">O XP acumulado sobe o teu nível. Em "Estatísticas" vês o streak, XP total e o desempenho por tópico.</p>
                </div>
              </div>
            </div>
          </template>

          <!-- Página 4: Andy e Reportar -->
          <template v-else>
            <div class="flex flex-col items-center text-center mb-5">
              <div class="w-20 h-20 rounded-2xl border border-brand/40 bg-background flex items-center justify-center mb-4">
                <img src="/chatbot.png" alt="Andy" class="w-13 h-13 object-contain" />
              </div>
              <h2 class="text-xl font-bold">Andy e Reportar</h2>
            </div>
            <div class="space-y-4">
              <div v-for="rule in andyRules" :key="rule.title" class="flex gap-3">
                <div class="w-8 h-8 rounded-full flex items-center justify-center shrink-0 mt-0.5" :style="{ background: rule.bg }">
                  <i :class="rule.icon" class="text-sm" :style="{ color: rule.color }"></i>
                </div>
                <div>
                  <p class="font-semibold text-sm mb-0.5">{{ rule.title }}</p>
                  <p class="text-text-secondary text-sm leading-relaxed">{{ rule.desc }}</p>
                </div>
              </div>
            </div>
          </template>

        </div>

        <!-- Footer nav -->
        <div class="flex items-center justify-between px-4 sm:px-6 py-4 border-t border-white/5 shrink-0">
          <button
            @click="active = Math.max(0, active - 1)"
            :disabled="active === 0"
            class="px-4 py-2 rounded-btn border border-white/10 text-sm hover:border-brand/50 transition-all disabled:opacity-30"
          >
            <i class="pi pi-arrow-left mr-1"></i> Anterior
          </button>
          <span class="flex gap-1.5">
            <span
              v-for="(_, i) in 4"
              :key="i"
              class="h-1.5 rounded-full transition-all"
              :class="i === active ? 'bg-brand w-4' : 'bg-white/20 w-1.5'"
            ></span>
          </span>
          <button
            v-if="active < 3"
            @click="active = active + 1"
            class="px-4 py-2 rounded-btn bg-brand text-white text-sm hover:brightness-110 transition-all"
          >
            Próximo <i class="pi pi-arrow-right ml-1"></i>
          </button>
          <button
            v-else
            @click="close"
            class="px-4 py-2 rounded-btn bg-brand text-white text-sm hover:brightness-110 transition-all"
          >
            Vamos começar! <i class="pi pi-check ml-1"></i>
          </button>
        </div>

      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';

const props = defineProps<{ modelValue: boolean }>();
const emit = defineEmits<{ 'update:modelValue': [value: boolean] }>();

const active = ref(0);

watch(() => props.modelValue, (v) => { if (v) active.value = 0; });

function close() {
  emit('update:modelValue', false);
}

const sections = [
  { icon: 'pi pi-map', label: 'Percursos' },
  { icon: 'pi pi-list', label: 'Prática' },
  { icon: 'pi pi-bolt', label: 'Quizzes' },
  { icon: 'pi pi-chart-bar', label: 'Estatísticas' },
];

const courseRules = [
  {
    icon: 'pi pi-chart-line',
    color: '#4ade80',
    bg: 'rgba(74,222,128,0.12)',
    title: 'Progressão por dificuldade',
    desc: 'Nos percursos, cada tópico segue a ordem Fácil → Médio → Difícil. Completa um nível para desbloquear o seguinte.',
  },
  {
    icon: 'pi pi-bolt',
    color: '#60a5fa',
    bg: 'rgba(96,165,250,0.12)',
    title: 'Prática livre com filtros',
    desc: 'Em "Praticar" podes escolher a disciplina, tópico, tipo e dificuldade — e fazer scroll vertical para passar de exercício.',
  },
  {
    icon: 'pi pi-sparkles',
    color: '#a78bfa',
    bg: 'rgba(167,139,250,0.12)',
    title: 'Explicação automática',
    desc: 'Após responderes aparece sempre uma explicação. Clica em "Pedir explicação ao Andy" para aprofundar com IA.',
  },
];

const xpTable = [
  { diff: 'Fácil',  base: 10, bonus: 15, cls: 'bg-green-500/20 text-green-400' },
  { diff: 'Médio',  base: 20, bonus: 30, cls: 'bg-yellow-500/20 text-yellow-400' },
  { diff: 'Difícil', base: 35, bonus: 53, cls: 'bg-red-500/20 text-red-400' },
];

const andyRules = [
  {
    icon: 'pi pi-sparkles',
    color: '#a78bfa',
    bg: 'rgba(167,139,250,0.12)',
    title: 'Pede ajuda ao Andy',
    desc: 'Após qualquer exercício, clica em "Pedir explicação ao Andy" para receberes uma explicação personalizada com IA — quer tenhas acertado ou errado.',
  },
  {
    icon: 'pi pi-flag',
    color: '#f87171',
    bg: 'rgba(248,113,113,0.12)',
    title: 'Reportar um problema',
    desc: 'Se encontrares um exercício com erro ou enunciado confuso, clica no botão vermelho "Reportar problema". A equipa docente fica notificada.',
  },
  {
    icon: 'pi pi-question-circle',
    color: '#94a3b8',
    bg: 'rgba(148,163,184,0.12)',
    title: 'Rever este guia',
    desc: 'Podes voltar a ver este guia a qualquer momento clicando no botão "?" na barra lateral.',
  },
];
</script>
