<script setup>
import { computed } from 'vue';
import { BaseEdge, getBezierPath } from '@vue-flow/core';

const props = defineProps({
  sourceX: { type: Number, required: true },
  sourceY: { type: Number, required: true },
  targetX: { type: Number, required: true },
  targetY: { type: Number, required: true },
  sourcePosition: { type: String, required: true },
  targetPosition: { type: String, required: true },
  selected: { type: Boolean, default: false },
});

const path = computed(
  () =>
    getBezierPath({
      sourceX: props.sourceX,
      sourceY: props.sourceY,
      targetX: props.targetX,
      targetY: props.targetY,
      sourcePosition: props.sourcePosition,
      targetPosition: props.targetPosition,
    })[0]
);
</script>

<template>
  <BaseEdge
    :path="path"
    :style="{
      stroke: selected ? '#a78bfa' : '#52525b',
      strokeWidth: selected ? 3 : 2,
    }"
  />
</template>
