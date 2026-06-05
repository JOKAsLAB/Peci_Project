<template>
  <Teleport to="body">
    <div
      v-if="visible"
      class="fixed inset-0 z-[120] flex items-center justify-center px-4"
    >
      <div
        class="absolute inset-0 bg-black/65 backdrop-blur-sm"
        @click="handleBackdrop"
      ></div>

      <div
        class="relative panel-surface border border-white/10 rounded-card w-full max-w-md p-6 shadow-2xl"
      >
        <div class="flex items-start gap-3">
          <div
            class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
            :class="iconWrapperClass"
          >
            <i :class="iconClass" class="text-sm"></i>
          </div>

          <div class="flex-1">
            <h4 class="text-lg font-bold text-text-primary">{{ title }}</h4>
            <p class="mt-2 text-sm text-text-secondary whitespace-pre-line">
              {{ message }}
            </p>
          </div>
        </div>

        <div class="mt-6 flex justify-end gap-3">
          <button
            v-if="showCancel"
            type="button"
            class="px-4 py-2 rounded-btn text-sm border border-white/10 text-text-secondary hover:text-white"
            :disabled="loading"
            @click="cancel"
          >
            {{ cancelText }}
          </button>

          <button
            type="button"
            class="px-4 py-2 rounded-btn text-sm font-bold transition-all disabled:opacity-60"
            :class="confirmButtonClass"
            :disabled="loading"
            @click="confirm"
          >
            <i v-if="loading" class="pi pi-spin pi-spinner mr-2"></i>
            {{ confirmText }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue';

type DialogVariant = 'primary' | 'danger' | 'success';

const props = withDefaults(
  defineProps<{
    visible: boolean;
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    showCancel?: boolean;
    loading?: boolean;
    allowBackdropClose?: boolean;
    variant?: DialogVariant;
  }>(),
  {
    confirmText: 'Confirmar',
    cancelText: 'Cancelar',
    showCancel: true,
    loading: false,
    allowBackdropClose: true,
    variant: 'primary',
  },
);

const emit = defineEmits<{
  (e: 'update:visible', value: boolean): void;
  (e: 'confirm'): void;
}>();

const iconWrapperClass = computed(() => {
  if (props.variant === 'danger')
    return 'bg-error/15 text-error border border-error/25';
  if (props.variant === 'success')
    return 'bg-success/15 text-success border border-success/25';
  return 'bg-brand/15 text-brand border border-brand/25';
});

const iconClass = computed(() => {
  if (props.variant === 'danger') return 'pi pi-exclamation-triangle';
  if (props.variant === 'success') return 'pi pi-check-circle';
  return 'pi pi-question-circle';
});

const confirmButtonClass = computed(() => {
  if (props.variant === 'danger')
    return 'bg-error text-white hover:brightness-110';
  if (props.variant === 'success')
    return 'bg-success text-black hover:brightness-110';
  return 'bg-brand text-white hover:brightness-110';
});

function close(): void {
  emit('update:visible', false);
}

function handleBackdrop(): void {
  if (!props.allowBackdropClose || props.loading) return;
  close();
}

function cancel(): void {
  if (props.loading) return;
  close();
}

function confirm(): void {
  emit('confirm');
}
</script>
