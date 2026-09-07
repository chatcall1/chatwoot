<script setup>
import { computed } from 'vue';
import { Handle, Position } from '@vue-flow/core';
import NodeActions from './NodeActions.vue';

const props = defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
});
defineEmits(['duplicate', 'delete']);

const outputs = computed(() => [
  {
    id: 'buttons',
    label: 'أزرار',
    disabled: false,
  },
  {
    id: 'list',
    label: 'رسالة قائمة',
    disabled: false,
  },
  { id: 'next', label: 'التالي', disabled: false },
]);

const headerLabel = computed(
  () =>
    ({
      none: 'بدون هيدر',
      text: 'هيدر نصي',
      image: 'صورة',
      video: 'فيديو',
      document: 'مستند',
    })[props.data.headerType]
);
const platformLabel = 'WhatsApp';
const nodeLabel = 'تفاعلي';
</script>

<template>
  <article
    class="relative w-72 rounded-2xl border bg-n-background shadow-xl transition"
    :class="
      selected ? 'border-n-brand ring-2 ring-n-brand/20' : 'border-n-strong'
    "
  >
    <NodeActions
      :selected="selected"
      @duplicate="$emit('duplicate')"
      @delete="$emit('delete')"
    />
    <Handle
      type="target"
      :position="Position.Top"
      class="!size-3 !border-2 !border-black !bg-n-slate-8"
    />
    <header class="flex items-center gap-3 border-b border-n-weak px-4 py-3">
      <span
        class="flex size-9 items-center justify-center rounded-xl bg-n-teal-3 text-n-teal-11"
      >
        <span class="i-lucide-list-tree size-4" />
      </span>
      <div class="min-w-0">
        <p class="text-[10px] font-semibold uppercase text-n-teal-11">
          {{ platformLabel }}
        </p>
        <h3 class="truncate text-sm font-medium text-n-slate-12">
          {{ nodeLabel }}
        </h3>
      </div>
      <span class="ms-auto text-[10px] text-n-slate-9">{{ headerLabel }}</span>
    </header>

    <p class="line-clamp-3 min-h-14 px-4 py-3 text-xs text-n-slate-11">
      {{ data.body || 'أضف نص الرسالة التفاعلية' }}
    </p>

    <div class="grid grid-cols-3 gap-1 border-t border-n-weak px-3 py-2">
      <div
        v-for="(output, index) in outputs"
        :key="output.id"
        class="rounded-lg bg-n-alpha-2 px-2 py-2 text-center text-xs text-n-slate-12"
        :class="output.disabled && 'opacity-40'"
      >
        {{ output.label }}
        <Handle
          :id="output.id"
          type="source"
          :connectable="!output.disabled"
          :position="Position.Bottom"
          class="!size-3 !border-2 !border-black !bg-n-brand"
          :class="output.disabled && '!pointer-events-none !bg-n-slate-7'"
          :style="{ left: `${(index + 1) * 25}%` }"
        />
      </div>
    </div>
  </article>
</template>
