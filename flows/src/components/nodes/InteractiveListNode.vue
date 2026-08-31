<script setup>
import { Handle, Position } from '@vue-flow/core';

defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
});
const nodeLabel = 'رسالة قائمة';
</script>

<template>
  <article
    class="w-56 rounded-xl border bg-n-background shadow-lg transition"
    :class="
      selected ? 'border-n-brand ring-2 ring-n-brand/20' : 'border-n-strong'
    "
  >
    <Handle
      type="target"
      :position="Position.Left"
      class="!size-3 !border-2 !border-black !bg-n-slate-8"
    />
    <header class="flex items-center gap-2 border-b border-n-weak px-3 py-3">
      <span class="i-lucide-list size-4 text-n-teal-11" />
      <span class="text-sm font-medium text-n-slate-12">{{ nodeLabel }}</span>
    </header>
    <div class="space-y-1 px-3 py-2">
      <p
        v-for="row in data.rows"
        :key="row.id"
        class="truncate rounded-md bg-n-alpha-2 px-2 py-1 text-xs text-n-slate-11"
      >
        {{ row.title }}
      </p>
    </div>
    <Handle
      type="source"
      :position="Position.Right"
      class="!size-3 !border-2 !border-black !bg-n-brand"
    />
  </article>
</template>
