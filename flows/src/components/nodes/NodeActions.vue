<script setup>
defineProps({ selected: { type: Boolean, default: false } });
defineEmits(['duplicate', 'delete']);

const duplicateLabel = 'نسخ النود';
const deleteLabel = 'حذف النود';
</script>

<template>
  <div class="contents">
    <div
      v-if="selected"
      class="nodrag nopan absolute -right-12 top-2 z-10 ms-2 flex overflow-hidden rounded-lg border border-n-strong bg-n-background shadow-lg"
    >
      <button
        type="button"
        class="flow-icon-btn !rounded-none"
        :aria-label="duplicateLabel"
        :title="duplicateLabel"
        @click.stop="$emit('duplicate')"
      >
        <span class="i-lucide-copy size-4" />
      </button>
      <button
        type="button"
        class="flow-icon-btn !rounded-none text-n-ruby-11"
        :aria-label="deleteLabel"
        :title="deleteLabel"
        @click.stop="$emit('delete')"
      >
        <span class="i-lucide-trash-2 size-4" />
      </button>
    </div>
  </div>
</template>
