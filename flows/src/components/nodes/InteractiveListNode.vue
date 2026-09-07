<script setup>
import { Handle, Position } from '@vue-flow/core';
import NodeActions from './NodeActions.vue';

defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
});
defineEmits(['duplicate', 'delete']);
const nodeLabel = 'رسالة قائمة';
</script>

<template>
  <article
    class="relative w-56 rounded-xl border bg-n-background shadow-lg transition"
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
    <header class="flex items-center gap-2 border-b border-n-weak px-3 py-3">
      <span class="i-lucide-list size-4 text-n-teal-11" />
      <span class="text-sm font-medium text-n-slate-12">{{ nodeLabel }}</span>
    </header>
    <div class="px-3 py-2">
      <section
        v-for="section in data.sections"
        :key="section.id"
        class="mb-2 overflow-visible rounded-lg border border-n-strong last:mb-0"
      >
        <h4
          class="border-b border-n-strong bg-n-alpha-2 px-3 py-2 text-xs font-medium text-n-slate-12"
        >
          {{ section.title }}
        </h4>
        <div class="divide-y divide-n-weak">
          <div
            v-for="row in section.rows"
            :key="row.id"
            class="relative px-3 py-2 pe-5"
          >
            <p class="truncate text-xs font-medium text-n-slate-12">
              {{ row.title }}
            </p>
            <p
              v-if="row.description"
              class="truncate text-[10px] text-n-slate-9"
            >
              {{ row.description }}
            </p>
            <Handle
              :id="`row:${row.id}`"
              type="source"
              :position="Position.Right"
              class="!size-3 !border-2 !border-black !bg-n-brand"
            />
          </div>
        </div>
      </section>
    </div>
  </article>
</template>
