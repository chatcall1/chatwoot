<script setup>
import { computed } from 'vue';

const props = defineProps({
  menu: { type: Object, required: true },
  options: { type: Array, required: true },
});
const emit = defineEmits(['select', 'close']);
const menuStyle = computed(() => ({
  left: `${Math.min(props.menu.x, window.innerWidth - 224)}px`,
  top: `${Math.min(props.menu.y, window.innerHeight - 360)}px`,
}));
const title = 'اختر الرسالة التالية';
</script>

<template>
  <Teleport to="body">
    <div class="fixed inset-0 z-50" @pointerdown.self="emit('close')">
      <div
        class="absolute max-h-80 w-52 overflow-y-auto rounded-xl border border-n-strong bg-n-background p-2 shadow-xl"
        :style="menuStyle"
        dir="rtl"
      >
        <p class="px-2 py-1 text-xs font-medium text-n-slate-10">
          {{ title }}
        </p>
        <button
          v-for="option in options"
          :key="option.type"
          type="button"
          class="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
          @click="emit('select', option.type)"
        >
          <span class="size-4" :class="option.icon" />
          {{ option.label }}
        </button>
      </div>
    </div>
  </Teleport>
</template>
