<script setup>
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
defineProps({ data: { type: Object, required: true } });
defineEmits(['update']);
const bodyLabel = 'نص طلب الموقع';
</script>

<template>
  <TextArea
    :model-value="data.body"
    :label="bodyLabel"
    :max-length="1024"
    min-height="9rem"
    resize
    show-character-count
    @update:model-value="$emit('update', { ...data, body: $event })"
  />
</template>
