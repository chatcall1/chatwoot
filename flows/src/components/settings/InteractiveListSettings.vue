<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { generateId } from '../../utils/id';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);
const sectionsLabel = 'أقسام القائمة';
const completionHint = 'اربط النقطة اليمنى لكل صف برسالة تالية.';
const rowCount = computed(() =>
  props.data.sections.reduce((total, section) => total + section.rows.length, 0)
);
const rowCountLabel = computed(() => `${rowCount.value}/10`);
const patch = changes => emit('update', { ...props.data, ...changes });
const replaceSections = sections => patch({ sections });
const createRow = () => ({
  id: generateId(),
  title: `الخيار ${rowCount.value + 1}`,
  description: '',
});
const updateSection = (sectionId, changes) =>
  replaceSections(
    props.data.sections.map(section =>
      section.id === sectionId ? { ...section, ...changes } : section
    )
  );
const addSection = () => {
  if (props.data.sections.length >= 10 || rowCount.value >= 10) return;
  replaceSections([
    ...props.data.sections,
    {
      id: generateId(),
      title: `القسم ${props.data.sections.length + 1}`,
      rows: [createRow()],
    },
  ]);
};
const removeSection = sectionId => {
  if (props.data.sections.length <= 1) return;
  replaceSections(
    props.data.sections.filter(section => section.id !== sectionId)
  );
};
const addRow = section => {
  if (rowCount.value >= 10) return;
  updateSection(section.id, { rows: [...section.rows, createRow()] });
};
const updateRow = (section, rowId, changes) =>
  updateSection(section.id, {
    rows: section.rows.map(row =>
      row.id === rowId ? { ...row, ...changes } : row
    ),
  });
const removeRow = (section, rowId) => {
  if (rowCount.value <= 1) return;
  if (section.rows.length === 1) {
    removeSection(section.id);
    return;
  }
  updateSection(section.id, {
    rows: section.rows.filter(row => row.id !== rowId),
  });
};
</script>

<template>
  <Input
    :model-value="data.buttonText"
    label="نص زر فتح القائمة"
    maxlength="20"
    @update:model-value="patch({ buttonText: $event })"
  />
  <div class="space-y-3">
    <div class="flex items-center justify-between">
      <span class="flow-label">{{ sectionsLabel }}</span>
      <span class="text-xs text-n-slate-9">{{ rowCountLabel }}</span>
    </div>
    <section
      v-for="section in data.sections"
      :key="section.id"
      class="space-y-3 rounded-xl border-2 border-n-strong p-3"
    >
      <div class="flex items-end gap-2">
        <Input
          :model-value="section.title"
          label="عنوان القسم"
          maxlength="24"
          class="min-w-0 flex-1"
          @update:model-value="updateSection(section.id, { title: $event })"
        />
        <Button
          icon="i-lucide-trash-2"
          color="ruby"
          variant="ghost"
          size="sm"
          :disabled="data.sections.length <= 1"
          @click="removeSection(section.id)"
        />
      </div>
      <div
        v-for="row in section.rows"
        :key="row.id"
        class="space-y-2 rounded-lg border border-n-strong p-3"
      >
        <Input
          :model-value="row.title"
          label="عنوان الصف"
          maxlength="24"
          @update:model-value="updateRow(section, row.id, { title: $event })"
        />
        <Input
          :model-value="row.description"
          label="وصف الصف"
          maxlength="72"
          @update:model-value="
            updateRow(section, row.id, { description: $event })
          "
        />
        <Button
          label="حذف الصف"
          icon="i-lucide-trash-2"
          color="ruby"
          variant="ghost"
          size="sm"
          :disabled="rowCount <= 1"
          @click="removeRow(section, row.id)"
        />
      </div>
      <Button
        label="إضافة صف"
        icon="i-lucide-plus"
        color="slate"
        variant="faded"
        size="sm"
        :disabled="rowCount >= 10"
        @click="addRow(section)"
      />
    </section>
    <Button
      label="إضافة قسم"
      icon="i-lucide-folder-plus"
      color="slate"
      variant="faded"
      size="sm"
      :disabled="data.sections.length >= 10 || rowCount >= 10"
      @click="addSection"
    />
  </div>
  <p class="text-xs text-n-slate-10">{{ completionHint }}</p>
</template>
