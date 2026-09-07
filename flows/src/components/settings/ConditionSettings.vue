<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);

const sourceOptions = [
  { value: 'incoming_message', label: 'رسالة التشغيل الأولى' },
  { value: 'last_choice', label: 'آخر اختيار من زر أو قائمة' },
];
const operatorOptions = [
  { value: 'equals', label: 'يساوي' },
  { value: 'not_equals', label: 'لا يساوي' },
  { value: 'contains', label: 'يحتوي على' },
  { value: 'not_contains', label: 'لا يحتوي على' },
];
const patch = changes => emit('update', { ...props.data, ...changes });
</script>

<template>
  <div class="space-y-5">
    <Select
      :model-value="data.source"
      label="مصدر القيمة"
      :options="sourceOptions"
      @update:model-value="patch({ source: $event })"
    />
    <Select
      :model-value="data.operator"
      label="نوع المقارنة"
      :options="operatorOptions"
      @update:model-value="patch({ operator: $event })"
    />
    <Input
      :model-value="data.value"
      label="القيمة"
      maxlength="4096"
      @update:model-value="patch({ value: $event })"
    />
  </div>
</template>
