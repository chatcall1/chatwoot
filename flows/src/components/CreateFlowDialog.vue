<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import AppDialog from './AppDialog.vue';
import { PLATFORM_OPTIONS } from '../domain/constants';
import Input from 'dashboard/components-next/input/Input.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  inboxes: { type: Array, default: () => [] },
  flows: { type: Array, default: () => [] },
});
const emit = defineEmits(['close', 'create']);
const { t } = useI18n();

const form = reactive({
  name: '',
  platforms: [],
  inboxIds: [],
  templateId: '',
});
const isValid = computed(
  () => form.name.trim() && form.inboxIds.length && form.templateId
);

const PLATFORM_BY_CHANNEL = {
  'Channel::Whatsapp': 'whatsapp',
  'Channel::Instagram': 'instagram',
  'Channel::FacebookPage': 'messenger',
};
const PLATFORM_ORDER = {
  whatsapp: 0,
  instagram: 1,
  messenger: 2,
};

const supportedInboxes = computed(() =>
  props.inboxes
    .filter(inbox => PLATFORM_BY_CHANNEL[inbox.channel_type])
    .sort(
      (first, second) =>
        PLATFORM_ORDER[PLATFORM_BY_CHANNEL[first.channel_type]] -
          PLATFORM_ORDER[PLATFORM_BY_CHANNEL[second.channel_type]] ||
        first.name.localeCompare(second.name)
    )
);

const platformOption = inbox =>
  PLATFORM_OPTIONS.find(
    option => option.id === PLATFORM_BY_CHANNEL[inbox.channel_type]
  );

const templates = computed(() => {
  const common = [
    {
      id: 'exact_hours',
      icon: 'i-lucide-clock-3',
      label: t('FLOW_BUILDER.TEMPLATES.exact_hours.TITLE'),
      description: t('FLOW_BUILDER.TEMPLATES.exact_hours.DESCRIPTION'),
    },
    {
      id: 'exact_prices',
      icon: 'i-lucide-badge-dollar-sign',
      label: t('FLOW_BUILDER.TEMPLATES.exact_prices.TITLE'),
      description: t('FLOW_BUILDER.TEMPLATES.exact_prices.DESCRIPTION'),
    },
    {
      id: 'exact_order',
      icon: 'i-lucide-package-search',
      label: t('FLOW_BUILDER.TEMPLATES.exact_order.TITLE'),
      description: t('FLOW_BUILDER.TEMPLATES.exact_order.DESCRIPTION'),
    },
    {
      id: 'exact_support',
      icon: 'i-lucide-headset',
      label: t('FLOW_BUILDER.TEMPLATES.exact_support.TITLE'),
      description: t('FLOW_BUILDER.TEMPLATES.exact_support.DESCRIPTION'),
    },
  ];
  return form.platforms.includes('whatsapp')
    ? [
        {
          id: 'welcome_buttons',
          icon: 'i-lucide-gallery-vertical-end',
          label: t('FLOW_BUILDER.TEMPLATES.welcome_buttons.TITLE'),
          description: t('FLOW_BUILDER.TEMPLATES.welcome_buttons.DESCRIPTION'),
        },
        {
          id: 'welcome_list',
          icon: 'i-lucide-list-tree',
          label: t('FLOW_BUILDER.TEMPLATES.welcome_list.TITLE'),
          description: t('FLOW_BUILDER.TEMPLATES.welcome_list.DESCRIPTION'),
        },
        ...common,
      ]
    : common;
});
const replacesWelcomeDraft = computed(
  () =>
    form.templateId.startsWith('welcome_') &&
    props.flows.some(
      flow =>
        String(flow.inboxIds[0]) === String(form.inboxIds[0]) &&
        flow.graph.nodes.some(
          node => node.type === 'trigger' && node.data.mode === 'no_match'
        )
    )
);

watch(
  () => props.open,
  value => {
    if (!value) return;
    form.name = '';
    form.platforms = [];
    form.inboxIds = [];
    form.templateId = '';
  }
);

const selectInbox = inboxId => {
  const inbox = supportedInboxes.value.find(
    item => String(item.id) === String(inboxId)
  );
  if (!inbox) return;
  form.inboxIds = [inbox.id];
  form.platforms = [PLATFORM_BY_CHANNEL[inbox.channel_type]];
  if (!templates.value.some(template => template.id === form.templateId)) {
    form.templateId = '';
  }
};

const submit = () => {
  if (!isValid.value) return;
  emit('create', {
    name: form.name,
    platforms: form.platforms,
    inboxIds: form.inboxIds,
    templateId: form.templateId,
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
          class="grid max-h-72 gap-2 overflow-y-auto"
          :class="
            supportedInboxes.length === 1
              ? 'grid-cols-1'
              : 'grid-cols-1 sm:grid-cols-2'
          "
        >
          <RadioCard
            v-for="inbox in supportedInboxes"
            :id="String(inbox.id)"
            :key="inbox.id"
            name="flow-inbox"
            :label="inbox.name"
            :description="platformOption(inbox)?.label || ''"
            :is-active="form.inboxIds.includes(inbox.id)"
            class="!border-2 !p-2 !outline-none [&>div]:!gap-1"
            :class="
              form.inboxIds.includes(inbox.id)
                ? '!border-n-slate-12'
                : '!border-n-strong hover:!border-n-slate-11'
            "
            @select="selectInbox"
          >
            <template #icon>
              <span
                class="flex size-8 items-center justify-center rounded-lg bg-n-alpha-2 text-n-slate-11"
              >
                <span class="size-4" :class="platformOption(inbox)?.icon" />
              </span>
            </template>
          </RadioCard>
        </div>
        <p v-else class="rounded-lg bg-n-alpha-2 p-4 text-sm text-n-slate-11">
          {{ $t('FLOW_BUILDER.DIALOG.NO_INBOXES') }}
        </p>
      </fieldset>

      <fieldset v-if="form.inboxIds.length">
        <legend class="flow-label">
          {{ $t('FLOW_BUILDER.DIALOG.TEMPLATES') }}
        </legend>
        <div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
          <RadioCard
            v-for="template in templates"
            :id="template.id"
            :key="template.id"
            name="flow-template"
            :label="template.label"
            :description="template.description"
            :is-active="form.templateId === template.id"
            class="!border-2 !p-3 !outline-none"
            :class="
              form.templateId === template.id
                ? '!border-n-slate-12'
                : '!border-n-strong hover:!border-n-slate-11'
            "
            @select="form.templateId = template.id"
          >
            <template #icon>
              <span class="size-5 text-n-slate-11" :class="template.icon" />
            </template>
          </RadioCard>
        </div>
        <p
          v-if="replacesWelcomeDraft"
          class="mt-3 flex items-start gap-2 rounded-lg border border-n-strong bg-n-alpha-2 p-3 text-sm text-n-slate-11"
        >
          <span class="i-lucide-triangle-alert mt-0.5 size-4 shrink-0" />
          {{ $t('FLOW_BUILDER.DIALOG.REPLACE_WELCOME_WARNING') }}
        </p>
      </fieldset>
    </div>
  </AppDialog>
</template>
