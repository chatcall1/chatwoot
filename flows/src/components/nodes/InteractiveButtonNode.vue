<script setup>
import { Handle, Position } from '@vue-flow/core';
import NodeActions from './NodeActions.vue';

defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
});
defineEmits(['duplicate', 'delete']);
</script>

<template>
  <article
    class="relative w-48 rounded-xl border bg-n-background shadow-lg transition"
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
    <div class="flex items-center gap-2 px-3 py-3">
      <span class="i-lucide-mouse-pointer-click size-4 text-n-blue-11" />
      <span class="truncate text-sm font-medium text-n-slate-12">
        {{ data.title }}
      </span>
    </div>
    <Handle
      type="source"
      :position="Position.Bottom"
      class="!size-3 !border-2 !border-black !bg-n-brand"
    />
  </article>
</template>
