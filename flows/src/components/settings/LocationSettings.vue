<script setup>
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);
const patch = changes => emit('update', { ...props.data, ...changes });
const latitudeLabel = 'خط العرض';
const longitudeLabel = 'خط الطول';
const nameLabel = 'اسم الموقع';
const addressLabel = 'العنوان';
</script>

<template>
  <div class="grid grid-cols-2 gap-3">
    <Input
      :model-value="data.latitude"
      type="number"
      :label="latitudeLabel"
      step="any"
      @update:model-value="patch({ latitude: $event })"
    />
    <Input
      :model-value="data.longitude"
      type="number"
      :label="longitudeLabel"
      step="any"
      @update:model-value="patch({ longitude: $event })"
    />
  </div>
  <Input
    :model-value="data.name"
    :label="nameLabel"
    @update:model-value="patch({ name: $event })"
  />
  <Input
    :model-value="data.address"
    :label="addressLabel"
    @update:model-value="patch({ address: $event })"
  />
</template>
