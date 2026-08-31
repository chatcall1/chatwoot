<script setup>
import { ref, watch } from 'vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  title: { type: String, required: true },
  description: { type: String, default: '' },
  confirmLabel: { type: String, default: 'تأكيد' },
  destructive: { type: Boolean, default: false },
  confirmDisabled: { type: Boolean, default: false },
});

const emit = defineEmits(['close', 'confirm']);
const dialogRef = ref(null);

watch(
  () => props.open,
  value => {
    if (value) dialogRef.value?.open();
    else dialogRef.value?.close();
  }
);

const close = () => emit('close');
</script>

<template>
  <Dialog
    ref="dialogRef"
    :type="destructive ? 'alert' : 'edit'"
    :title="title"
    :description="description"
    :confirm-button-label="confirmLabel"
    :cancel-button-label="$t('FLOW_BUILDER.DIALOG.CANCEL')"
    :disable-confirm-button="confirmDisabled"
    width="lg"
    @close="close"
    @confirm="$emit('confirm')"
  >
    <slot />
  </Dialog>
</template>
