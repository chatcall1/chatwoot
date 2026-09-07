<script setup>
import { computed } from 'vue';
import { BaseEdge, getBezierPath } from '@vue-flow/core';

const props = defineProps({
  id: { type: String, required: true },
  sourceX: { type: Number, required: true },
  sourceY: { type: Number, required: true },
  targetX: { type: Number, required: true },
  targetY: { type: Number, required: true },
  sourcePosition: { type: String, required: true },
  targetPosition: { type: String, required: true },
  selected: { type: Boolean, default: false },
});
defineEmits(['delete']);

const edgePath = computed(() =>
  getBezierPath({
    sourceX: props.sourceX,
    sourceY: props.sourceY,
    targetX: props.targetX,
    targetY: props.targetY,
    sourcePosition: props.sourcePosition,
    targetPosition: props.targetPosition,
  })
);
const path = computed(() => edgePath.value[0]);
const labelX = computed(() => edgePath.value[1]);
const labelY = computed(() => edgePath.value[2]);
const deleteLabel = 'حذف الربط';
</script>

<template>
  <BaseEdge
    :path="path"
    :style="{
      stroke: selected ? '#a78bfa' : '#52525b',
      strokeWidth: selected ? 3 : 2,
    }"
  />
  <g
    class="vue-flow__edge-interaction nodrag nopan cursor-pointer"
    :transform="`translate(${labelX} ${labelY})`"
    role="button"
    tabindex="0"
    :aria-label="deleteLabel"
    @click.stop="$emit('delete', id)"
    @keydown.enter.stop="$emit('delete', id)"
  >
    <circle r="13" fill="#18181b" stroke="#71717a" stroke-width="2" />
    <path
      d="M -4 -4 L 4 4 M 4 -4 L -4 4"
      fill="none"
      stroke="#f4f4f5"
      stroke-linecap="round"
      stroke-width="2.5"
    />
    <title>{{ deleteLabel }}</title>
  </g>
</template>
