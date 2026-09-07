<script setup>
import { computed } from 'vue';
import { Handle, Position } from '@vue-flow/core';
import NodeActions from './NodeActions.vue';

const props = defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
});
defineEmits(['duplicate', 'delete']);

const operatorLabel = computed(
  () =>
    ({
      equals: 'يساوي',
      not_equals: 'لا يساوي',
      contains: 'يحتوي على',
      not_contains: 'لا يحتوي على',
    })[props.data.operator]
);
const sourceLabel = computed(() =>
  props.data.source === 'last_choice'
    ? 'آخر اختيار للعميل'
    : 'رسالة التشغيل الأولى'
);
const nodeLabel = 'شرط';
const matchedLabel = 'تحقق';
const notMatchedLabel = 'لم يتحقق';
const emptyValueLabel = 'حدد قيمة المقارنة';
const valueSeparator = ':';
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
        class="flex size-9 items-center justify-center rounded-xl bg-n-amber-3 text-n-amber-11"
      >
        <span class="i-lucide-git-branch size-4" />
      </span>
      <div class="min-w-0">
        <p class="text-[10px] font-semibold uppercase text-n-amber-11">
          {{ nodeLabel }}
        </p>
        <h3 class="truncate text-sm font-medium text-n-slate-12">
          {{ sourceLabel }}
        </h3>
      </div>
    </header>
    <p class="truncate px-4 py-3 text-xs text-n-slate-11">
      {{ operatorLabel }}{{ valueSeparator }}
      {{ data.value || emptyValueLabel }}
    </p>
    <div class="grid grid-cols-2 gap-2 border-t border-n-weak px-3 py-2">
      <div
        class="relative rounded-lg bg-n-teal-3 px-2 py-2 text-center text-xs text-n-teal-11"
      >
        {{ matchedLabel }}
        <Handle
          id="matched"
          type="source"
          :position="Position.Bottom"
          class="!size-3 !border-2 !border-black !bg-n-teal-9"
        />
      </div>
      <div
        class="relative rounded-lg bg-n-ruby-3 px-2 py-2 text-center text-xs text-n-ruby-11"
      >
        {{ notMatchedLabel }}
        <Handle
          id="not_matched"
          type="source"
          :position="Position.Bottom"
          class="!size-3 !border-2 !border-black !bg-n-ruby-9"
        />
      </div>
    </div>
  </article>
</template>
