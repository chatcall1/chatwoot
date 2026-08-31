<script setup>
import { computed, reactive, watch } from 'vue';
import AppDialog from './AppDialog.vue';
import { PLATFORM_OPTIONS } from '../domain/constants';
import Input from 'dashboard/components-next/input/Input.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  inboxes: { type: Array, default: () => [] },
});
const emit = defineEmits(['close', 'create']);

const form = reactive({
  name: '',
  platforms: [],
  inboxIds: [],
  triggerMode: 'keywords',
});
const isValid = computed(() => form.name.trim() && form.inboxIds.length);

const PLATFORM_BY_CHANNEL = {
  'Channel::Whatsapp': 'whatsapp',
  'Channel::Instagram': 'instagram',
  'Channel::FacebookPage': 'messenger',
};

const supportedInboxes = computed(() =>
  props.inboxes.filter(inbox => PLATFORM_BY_CHANNEL[inbox.channel_type])
);

watch(
  () => props.open,
  value => {
    if (!value) return;
    form.name = '';
    form.platforms = [];
    form.inboxIds = [];
    form.triggerMode = 'keywords';
  }
);

const selectInbox = inboxId => {
  const inbox = supportedInboxes.value.find(
    item => String(item.id) === String(inboxId)
  );
  if (!inbox) return;
  form.inboxIds = [inbox.id];
  form.platforms = [PLATFORM_BY_CHANNEL[inbox.channel_type]];
};

const submit = () => {
  if (!isValid.value) return;
  emit('create', {
    name: form.name,
    platforms: form.platforms,
    inboxIds: form.inboxIds,
    triggerMode: form.triggerMode,
  });
};
</script>

<template>
  <AppDialog
    :open="open"
    :title="$t('FLOW_BUILDER.DIALOG.CREATE_TITLE')"
    :description="$t('FLOW_BUILDER.DIALOG.CREATE_DESCRIPTION')"
    :confirm-label="$t('FLOW_BUILDER.DIALOG.CREATE_CONFIRM')"
    :confirm-disabled="!isValid"
    @close="$emit('close')"
    @confirm="submit"
  >
    <div class="space-y-5">
      <Input
        v-model="form.name"
        :label="$t('FLOW_BUILDER.DIALOG.NAME')"
        :placeholder="$t('FLOW_BUILDER.DIALOG.NAME_PLACEHOLDER')"
        maxlength="80"
      />

      <fieldset>
        <legend class="flow-label">
          {{ $t('FLOW_BUILDER.DIALOG.INBOXES') }}
        </legend>
        <div
          v-if="supportedInboxes.length"
          class="grid max-h-52 grid-cols-2 gap-2 overflow-y-auto"
        >
          <RadioCard
            v-for="inbox in supportedInboxes"
            :id="String(inbox.id)"
            :key="inbox.id"
            name="flow-inbox"
            :label="inbox.name"
            :description="
              PLATFORM_OPTIONS.find(
                item => item.id === PLATFORM_BY_CHANNEL[inbox.channel_type]
              )?.label || ''
            "
            :is-active="form.inboxIds.includes(inbox.id)"
            class="!p-2 [&>div]:!gap-1"
            @select="selectInbox"
          />
        </div>
        <p v-else class="rounded-lg bg-n-alpha-2 p-4 text-sm text-n-slate-11">
          {{ $t('FLOW_BUILDER.DIALOG.NO_INBOXES') }}
        </p>
      </fieldset>

      <fieldset>
        <legend class="flow-label">
          {{ $t('FLOW_BUILDER.DIALOG.TRIGGER_TYPE') }}
        </legend>
        <div class="grid grid-cols-2 gap-2">
          <RadioCard
            v-for="option in [
              { id: 'keywords', label: 'كلمات مفتاحية' },
              { id: 'no_match', label: 'No Match' },
            ]"
            :id="option.id"
            :key="option.id"
            name="trigger-mode"
            :label="option.label"
            :description="option.label"
            :is-active="form.triggerMode === option.id"
            class="!p-2 [&>div]:!gap-1"
            @select="form.triggerMode = $event"
          />
        </div>
      </fieldset>
    </div>
  </AppDialog>
</template>
