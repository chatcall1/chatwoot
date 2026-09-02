<script setup>
import { reactive, computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, requiredIf } from '@vuelidate/validators';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { isValidPhoneNumber } from 'libphonenumber-js';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';
import CampaignsAPI from 'dashboard/api/campaigns';
import ContactAPI from 'dashboard/api/contacts';
import InboxesAPI from 'dashboard/api/inboxes';
import InboxHealthAPI from 'dashboard/api/inboxHealth';

const emit = defineEmits(['submit', 'cancel', 'update:dirty']);
const { t } = useI18n();
const store = useStore();
const CUSTOM_MESSAGE = 'custom';
const MAX_PHONE_NUMBERS = 100;
const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getWhatsAppInboxes'),
  getFilteredWhatsAppTemplates: useMapGetter(
    'inboxes/getFilteredWhatsAppTemplates'
  ),
};
const state = reactive({
  title: '',
  inboxId: null,
  templateId: CUSTOM_MESSAGE,
  customMessage: '',
  audienceType: 'labels',
  phoneNumbersText: '',
  targetLabelIds: [],
  excludedLabelIds: [],
  conversationLabelIds: [],
  deliveryType: 'immediate',
  scheduledAt: null,
  testPhoneNumber: '',
});
const templateParserRef = ref(null);
const audienceFileInput = ref(null);
const audienceFile = ref(null);
const localTemplates = ref(null);
const isSendingTest = ref(false);
const isSyncingTemplates = ref(false);
const isLoadingHealth = ref(false);
const healthData = ref(null);
const audienceCount = ref(null);
const isCountingAudience = ref(false);
let countTimer;
const audienceImport = reactive({
  id: null,
  isImporting: false,
  isComplete: false,
  processedRecords: 0,
  rejectedRecords: 0,
  hasFailedRecords: false,
});
const normalizePhoneNumber = value =>
  value
    .replace(/[٠-٩]/g, digit => '0123456789'['٠١٢٣٤٥٦٧٨٩'.indexOf(digit)])
    .replace(/[۰-۹]/g, digit => '0123456789'['۰۱۲۳۴۵۶۷۸۹'.indexOf(digit)])
    .replace(/[\s\-()]/g, '')
    .replace(/^00/, '+');
const phoneNumberEntries = computed(() =>
  state.phoneNumbersText
    .replace(/\s+(?=(?:\+|00)\d)/g, '\n')
    .split(/[,;\n]+/)
    .map(normalizePhoneNumber)
    .filter(Boolean)
);
const validPhoneNumbers = computed(() => [
  ...new Set(
    phoneNumberEntries.value.filter(number => isValidPhoneNumber(number))
  ),
]);
const invalidPhoneNumbers = computed(() =>
  phoneNumberEntries.value.filter(number => !isValidPhoneNumber(number))
);
const isPhoneAudienceValid = () =>
  state.audienceType !== 'phones' ||
  (validPhoneNumbers.value.length > 0 &&
    invalidPhoneNumbers.value.length === 0);
const phoneNumbersModel = computed({
  get: () => state.phoneNumbersText,
  set: value => {
    const normalizedValue = value
      .replace(/\s+(?=(?:\+|00)\d)/g, '\n')
      .split(/([,;\n]+)/)
      .map(part => (/^[,;\n]+$/.test(part) ? part : normalizePhoneNumber(part)))
      .join('');
    const entries = normalizedValue.split(/[,;\n]+/).filter(Boolean);
    state.phoneNumbersText = entries.slice(0, MAX_PHONE_NUMBERS).join('\n');
  },
});
const fixPhoneNumbers = () => {
  state.phoneNumbersText = [...new Set(phoneNumberEntries.value)].join('\n');
};
const rules = computed(() => ({
  title: { required },
  inboxId: { required },
  templateId: { required },
  customMessage: {
    required: requiredIf(() => state.templateId === CUSTOM_MESSAGE),
  },
  targetLabelIds: {
    required: requiredIf(() => state.audienceType === 'labels'),
  },
  phoneNumbersText: { validPhoneNumbers: isPhoneAudienceValid },
  scheduledAt: {
    required: requiredIf(() => state.deliveryType === 'scheduled'),
  },
}));
const v$ = useVuelidate(rules, state);
const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({ value: item[valueKey], label: item[labelKey] })) ?? [];
const labelOptions = computed(() =>
  mapToOptions(formState.labels.value, 'id', 'title')
);
const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);
const templateOptions = computed(() => {
  const templates =
    localTemplates.value ||
    (state.inboxId
      ? formState.getFilteredWhatsAppTemplates.value(state.inboxId)
      : []);
  return [
    {
      value: CUSTOM_MESSAGE,
      label: t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.CUSTOM'),
    },
    ...templates.map(template => ({
      value: template.id,
      label: `${template.name.replace(/_/g, ' ')} (${template.language || 'en'})`,
      template,
    })),
  ];
});
const selectedTemplate = computed(
  () =>
    templateOptions.value.find(option => option.value === state.templateId)
      ?.template || null
);
const isCustomMessage = computed(() => state.templateId === CUSTOM_MESSAGE);
const testDescription = computed(() =>
  isCustomMessage.value
    ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.CUSTOM_DESCRIPTION')
    : t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.DESCRIPTION')
);
const hasRequiredTemplateParams = computed(
  () =>
    isCustomMessage.value || templateParserRef.value?.isFormInvalid === false
);
const currentDateTime = computed(() => {
  const now = new Date();
  return new Date(now.getTime() - now.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
});
const normalizedTestPhoneNumber = computed(() =>
  state.testPhoneNumber
    .toString()
    .replace(/[٠-٩]/g, digit => '0123456789'['٠١٢٣٤٥٦٧٨٩'.indexOf(digit)])
    .replace(/[۰-۹]/g, digit => '0123456789'['۰۱۲۳۴۵۶۷۸۹'.indexOf(digit)])
    .replace(/[\s\-()]/g, '')
    .replace(/^00/, '+')
);
const isTestPhoneValid = computed(() => {
  try {
    return isValidPhoneNumber(normalizedTestPhoneNumber.value);
  } catch {
    return false;
  }
});
const canSendTest = computed(
  () =>
    !v$.value.$invalid &&
    hasRequiredTemplateParams.value &&
    isTestPhoneValid.value &&
    !isSendingTest.value
);
const isSubmitDisabled = computed(
  () =>
    v$.value.$invalid ||
    !hasRequiredTemplateParams.value ||
    audienceImport.isImporting ||
    (audienceFile.value && !audienceImport.isComplete)
);
const audienceCountDisplay = computed(() => {
  if (isCountingAudience.value) return '…';
  return audienceCount.value ?? '—';
});
const messagingLimitDisplay = computed(() => {
  const tier = healthData.value?.messaging_limit_tier;
  if (!tier) return '—';

  return tier.replace(/^TIER_/, '').replace(/K$/, '000');
});
const messagingLimit = computed(() => {
  const tier = healthData.value?.messaging_limit_tier?.replace(/^TIER_/, '');
  if (!tier || tier === 'UNLIMITED') return null;
  const match = tier.match(/^(\d+)(K|M)?$/);
  if (!match) return null;
  let multiplier = 1;
  if (match[2] === 'K') multiplier = 1000;
  if (match[2] === 'M') multiplier = 1000000;
  return Number(match[1]) * multiplier;
});
const exceedsMessagingLimit = computed(
  () =>
    !isCustomMessage.value &&
    audienceCount.value !== null &&
    messagingLimit.value !== null &&
    audienceCount.value > messagingLimit.value
);
const requiredSendingDays = computed(() =>
  exceedsMessagingLimit.value
    ? Math.ceil(audienceCount.value / messagingLimit.value)
    : 0
);
const buildTemplateParams = () => ({
  name: selectedTemplate.value?.name || '',
  namespace: selectedTemplate.value?.namespace || '',
  category: selectedTemplate.value?.category || 'UTILITY',
  language: selectedTemplate.value?.language || 'en_US',
  processed_params: templateParserRef.value?.processedParams || {},
});
const prepareCampaignDetails = () => ({
  title: state.title,
  message: isCustomMessage.value
    ? state.customMessage
    : templateParserRef.value?.renderedTemplate || '',
  template_params: isCustomMessage.value ? {} : buildTemplateParams(),
  inbox_id: state.inboxId,
  scheduled_at:
    state.deliveryType === 'immediate'
      ? new Date().toISOString()
      : new Date(state.scheduledAt).toISOString(),
  audience: state.targetLabelIds.map(id => ({ id, type: 'Label' })),
  trigger_rules: {
    message_type: isCustomMessage.value ? 'custom' : 'template',
    audience_type: state.audienceType,
    target_label_ids: state.targetLabelIds,
    excluded_label_ids: state.excludedLabelIds,
    conversation_label_ids: state.conversationLabelIds,
    phone_numbers: validPhoneNumbers.value,
  },
});
const refreshAudienceCount = async () => {
  if (
    !state.inboxId ||
    (state.audienceType === 'labels' && !state.targetLabelIds.length)
  ) {
    audienceCount.value = null;
    return;
  }
  isCountingAudience.value = true;
  try {
    const { data } = await CampaignsAPI.audienceCount(prepareCampaignDetails());
    audienceCount.value = data.count;
  } catch {
    audienceCount.value = null;
  } finally {
    isCountingAudience.value = false;
  }
};
const refreshHealth = async () => {
  if (!state.inboxId) return;
  isLoadingHealth.value = true;
  try {
    const { data } = await InboxHealthAPI.getHealthStatus(state.inboxId);
    healthData.value = data;
  } catch {
    healthData.value = null;
    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.CAPACITY.HEALTH_ERROR'));
  } finally {
    isLoadingHealth.value = false;
  }
};
const syncTemplates = async () => {
  if (!state.inboxId || isSyncingTemplates.value) return;
  isSyncingTemplates.value = true;
  try {
    await store.dispatch('inboxes/syncTemplates', state.inboxId);
    await new Promise(resolve => {
      setTimeout(resolve, 1500);
    });
    const { data } = await InboxesAPI.getMessageTemplates(state.inboxId);
    localTemplates.value = Array.isArray(data.payload) ? data.payload : null;
    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.SYNC_SUCCESS'));
  } catch {
    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.SYNC_ERROR'));
  } finally {
    isSyncingTemplates.value = false;
  }
};
const waitForImport = async (importId, attempt = 0) => {
  if (attempt >= 120) throw new Error('Import timed out');
  const { data } = await ContactAPI.importStatus(importId);
  if (['completed', 'completed_with_errors', 'failed'].includes(data.status))
    return data;
  await new Promise(resolve => {
    setTimeout(resolve, 1500);
  });
  return waitForImport(importId, attempt + 1);
};
const importAudience = async () => {
  if (!audienceFile.value || !state.inboxId) return;
  audienceImport.isImporting = true;
  try {
    const { data } = await ContactAPI.importContacts(audienceFile.value, {
      labelIds: state.targetLabelIds,
      inboxId: state.inboxId,
    });
    const result = await waitForImport(data.id);
    if (result.status === 'failed') throw new Error('Import failed');
    Object.assign(audienceImport, {
      id: result.id,
      isComplete: true,
      processedRecords: result.processed_records,
      rejectedRecords: result.rejected_records,
      hasFailedRecords: result.has_failed_records,
    });
    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.SUCCESS', result));
    refreshAudienceCount();
  } catch {
    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.ERROR'));
  } finally {
    audienceImport.isImporting = false;
  }
};
const downloadRejectedRows = async () => {
  const { data } = await ContactAPI.downloadFailedImportRecords(
    audienceImport.id
  );
  const url = URL.createObjectURL(data);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'failed-campaign-contacts.csv';
  link.click();
  URL.revokeObjectURL(url);
};
const sendTestTemplate = async () => {
  if (!canSendTest.value) return;
  isSendingTest.value = true;
  try {
    await CampaignsAPI.testTemplate({
      inbox_id: state.inboxId,
      phone_number: normalizedTestPhoneNumber.value,
      message_type: isCustomMessage.value ? 'custom' : 'template',
      message: isCustomMessage.value ? state.customMessage : undefined,
      template_params: isCustomMessage.value ? {} : buildTemplateParams(),
    });
    state.testPhoneNumber = normalizedTestPhoneNumber.value;
    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message ||
        t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.ERROR')
    );
  } finally {
    isSendingTest.value = false;
  }
};
const handleSubmit = async () => {
  if ((await v$.value.$validate()) && hasRequiredTemplateParams.value)
    emit('submit', prepareCampaignDetails());
};
watch(
  () => state.inboxId,
  () => {
    state.templateId = CUSTOM_MESSAGE;
    localTemplates.value = null;
    healthData.value = null;
    refreshHealth();
  }
);
watch(
  inboxOptions,
  options => {
    if (!options.length) return;
    if (options.some(option => option.value === state.inboxId)) return;

    state.inboxId = options[0].value;
  },
  { immediate: true }
);
watch(
  state,
  () => {
    emit(
      'update:dirty',
      Object.values(state).some(value =>
        Array.isArray(value) ? value.length : Boolean(value)
      )
    );
    clearTimeout(countTimer);
    countTimer = setTimeout(refreshAudienceCount, 400);
  },
  { deep: true }
);
</script>

<template>
  <form class="flex flex-col gap-6" @submit.prevent="handleSubmit">
    <section
      class="flex flex-col gap-4 p-5 border rounded-xl border-n-strong bg-n-blue-2"
    >
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SECTIONS.CHANNEL') }}
      </h3>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">{{
          t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.LABEL')
        }}</label>
        <ComboBox
          v-model="state.inboxId"
          :options="inboxOptions"
          :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.PLACEHOLDER')"
        />
      </div>
    </section>
    <section
      class="flex flex-col gap-4 p-5 border rounded-xl border-n-strong bg-n-blue-2"
    >
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SECTIONS.CONTENT') }}
      </h3>
      <div class="flex items-center justify-between gap-3">
        <label class="text-sm font-medium text-n-slate-12">{{
          t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.LABEL')
        }}</label>
        <Button
          type="button"
          size="sm"
          variant="ghost"
          color="slate"
          icon="i-lucide-refresh-cw"
          :is-loading="isSyncingTemplates"
          :disabled="!state.inboxId"
          :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.SYNC')"
          @click="syncTemplates"
        />
      </div>
      <ComboBox
        v-model="state.templateId"
        :options="templateOptions"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.PLACEHOLDER')"
      />
      <div
        v-if="isCustomMessage"
        class="flex gap-3 p-4 border rounded-lg border-n-strong bg-n-blue-2"
      >
        <span class="mt-0.5 i-lucide-clock-3 size-4 text-n-blue-11" />
        <p class="text-sm text-n-slate-12">
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.CUSTOM_INFO') }}
        </p>
      </div>
      <Input
        v-model="state.title"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.LABEL')"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.PLACEHOLDER')"
      />
      <TextArea
        v-if="isCustomMessage"
        v-model="state.customMessage"
        resize
        auto-height
        min-height="7rem"
        max-height="16rem"
        custom-text-area-wrapper-class="!border-n-strong !bg-n-blue-2"
        :placeholder="
          t('CAMPAIGN.WHATSAPP.CREATE.FORM.CUSTOM_MESSAGE.PLACEHOLDER')
        "
      />
      <WhatsAppTemplateParser
        v-else-if="selectedTemplate"
        ref="templateParserRef"
        :template="selectedTemplate"
      />
    </section>
    <section
      class="flex flex-col gap-4 p-5 border rounded-xl border-n-strong bg-n-blue-2"
    >
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SECTIONS.AUDIENCE') }}
      </h3>
      <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <button
          type="button"
          class="p-4 text-start border rounded-xl"
          :class="
            state.audienceType === 'labels'
              ? 'border-n-strong bg-n-blue-3'
              : 'border-n-strong'
          "
          @click="state.audienceType = 'labels'"
        >
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.BY_LABELS') }}
        </button>
        <button
          type="button"
          class="p-4 text-start border rounded-xl"
          :class="
            state.audienceType === 'all'
              ? 'border-n-strong bg-n-blue-3'
              : 'border-n-strong'
          "
          @click="state.audienceType = 'all'"
        >
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.ALL') }}
        </button>
        <button
          type="button"
          class="p-4 text-start border rounded-xl"
          :class="
            state.audienceType === 'phones'
              ? 'border-n-strong bg-n-blue-3'
              : 'border-n-strong'
          "
          @click="state.audienceType = 'phones'"
        >
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PHONE_NUMBERS') }}
        </button>
      </div>
      <TagMultiSelectComboBox
        v-if="state.audienceType === 'labels'"
        v-model="state.targetLabelIds"
        :options="labelOptions"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.TARGET_LABELS')"
      />
      <div v-if="state.audienceType === 'phones'" class="flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PHONE_NUMBERS') }}
          </label>
          <Button
            type="button"
            size="sm"
            variant="ghost"
            color="slate"
            icon="i-lucide-refresh-cw"
            class="flex-shrink-0"
            :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.FIX')"
            @click="fixPhoneNumbers"
          />
        </div>
        <TextArea
          v-model="phoneNumbersModel"
          dir="ltr"
          resize
          auto-height
          :max-lines="MAX_PHONE_NUMBERS"
          min-height="8rem"
          max-height="18rem"
          custom-text-area-class="font-mono !text-left"
          custom-text-area-wrapper-class="!border-n-strong !bg-n-blue-2"
          :placeholder="
            t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PHONE_PLACEHOLDER')
          "
        />
        <p class="text-xs text-n-slate-11">
          {{
            t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PHONE_HELP', {
              count: MAX_PHONE_NUMBERS,
            })
          }}
        </p>
        <p v-if="invalidPhoneNumbers.length" class="text-xs text-n-ruby-9">
          {{
            t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PHONE_INVALID', {
              numbers: invalidPhoneNumbers.join(', '),
            })
          }}
        </p>
        <p v-else-if="validPhoneNumbers.length" class="text-xs text-n-slate-11">
          {{
            t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PHONE_VALID_COUNT', {
              count: validPhoneNumbers.length,
            })
          }}
        </p>
      </div>
      <TagMultiSelectComboBox
        v-model="state.excludedLabelIds"
        :options="labelOptions"
        :placeholder="
          t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.EXCLUDED_LABELS')
        "
      />
      <TagMultiSelectComboBox
        v-model="state.conversationLabelIds"
        :options="labelOptions"
        :placeholder="
          t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.CONVERSATION_LABELS')
        "
      />
      <div
        v-if="state.audienceType !== 'phones'"
        class="flex flex-col gap-3 p-4 border rounded-lg border-n-strong bg-n-blue-2"
      >
        <div>
          <p class="text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.TITLE') }}
          </p>
          <p class="text-xs text-n-slate-11">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.DESCRIPTION') }}
            <a
              href="/downloads/import-contacts-sample.csv"
              download
              class="text-n-blue-11"
            >
              {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.DOWNLOAD') }}
            </a>
          </p>
        </div>
        <input
          ref="audienceFileInput"
          type="file"
          accept=".csv,text/csv"
          class="hidden"
          @change="
            audienceFile = $event.target.files?.[0] || null;
            audienceImport.isComplete = false;
          "
        />
        <div class="flex flex-wrap gap-2">
          <Button
            type="button"
            variant="ghost"
            color="slate"
            icon="i-lucide-upload"
            :label="
              audienceFile?.name ||
              t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.CHOOSE_FILE')
            "
            @click="audienceFileInput?.click()"
          /><Button
            v-if="audienceFile"
            type="button"
            :is-loading="audienceImport.isImporting"
            :disabled="!state.inboxId"
            :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.ACTION')"
            @click="importAudience"
          />
        </div>
        <p v-if="audienceImport.isComplete" class="text-xs text-n-slate-11">
          {{
            t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.RESULT', {
              processed: audienceImport.processedRecords,
              rejected: audienceImport.rejectedRecords,
            })
          }}
        </p>
        <Button
          v-if="audienceImport.hasFailedRecords"
          type="button"
          variant="ghost"
          color="slate"
          icon="i-lucide-download"
          class="!w-fit"
          :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.IMPORT.DOWNLOAD_REJECTED')"
          @click="downloadRejectedRows"
        />
      </div>
    </section>
    <section
      class="flex flex-col gap-4 p-5 border rounded-xl border-n-strong bg-n-blue-2"
    >
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SECTIONS.SCHEDULE') }}
      </h3>
      <div role="radiogroup" class="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div
          role="radio"
          tabindex="0"
          class="p-4 border-2 rounded-xl cursor-pointer border-n-slate-10"
          :class="
            state.deliveryType === 'immediate' ? 'bg-n-blue-3' : 'bg-n-blue-2'
          "
          :aria-checked="state.deliveryType === 'immediate'"
          @click="state.deliveryType = 'immediate'"
          @keydown.enter.space.self.prevent="state.deliveryType = 'immediate'"
        >
          <p class="font-medium text-start text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULE.IMMEDIATE') }}
          </p>
        </div>
        <div
          role="radio"
          tabindex="0"
          class="p-4 border-2 rounded-xl cursor-pointer border-n-slate-10"
          :class="
            state.deliveryType === 'scheduled' ? 'bg-n-blue-3' : 'bg-n-blue-2'
          "
          :aria-checked="state.deliveryType === 'scheduled'"
          @click="state.deliveryType = 'scheduled'"
          @keydown.enter.space.self.prevent="state.deliveryType = 'scheduled'"
        >
          <p class="font-medium text-start text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULE.LATER') }}
          </p>
          <Input
            v-if="state.deliveryType === 'scheduled'"
            v-model="state.scheduledAt"
            class="mt-3"
            type="datetime-local"
            :min="currentDateTime"
            :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.LABEL')"
          />
        </div>
      </div>
    </section>
    <section
      class="flex flex-col gap-3 p-5 border rounded-xl border-n-strong bg-n-blue-2"
    >
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.TITLE') }}
      </h3>
      <p class="text-xs text-n-slate-11">
        {{ testDescription }}
      </p>
      <div class="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-2">
        <Input
          v-model="state.testPhoneNumber"
          :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.PHONE_LABEL')"
          :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.PLACEHOLDER')"
          :message="
            state.testPhoneNumber && !isTestPhoneValid
              ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.PHONE_ERROR')
              : ''
          "
          :message-type="
            state.testPhoneNumber && !isTestPhoneValid ? 'error' : 'info'
          "
          @blur="state.testPhoneNumber = normalizedTestPhoneNumber"
        /><Button
          type="button"
          class="mt-6"
          :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEST.ACTION')"
          :is-loading="isSendingTest"
          :disabled="!canSendTest"
          @click="sendTestTemplate"
        />
      </div>
    </section>
    <div
      v-if="exceedsMessagingLimit"
      class="flex flex-col gap-2 p-4 border rounded-xl border-n-strong bg-n-blue-2"
    >
      <p class="text-sm font-medium text-n-ruby-9">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.CAPACITY.LIMIT_WARNING') }}
      </p>
      <p class="text-sm text-n-teal-10">
        {{
          t('CAMPAIGN.WHATSAPP.CREATE.FORM.CAPACITY.SPLIT_ADVICE', {
            days: requiredSendingDays,
          })
        }}
      </p>
    </div>
    <section class="grid grid-cols-1 gap-3 sm:grid-cols-2">
      <div class="p-5 border rounded-xl border-n-strong bg-n-blue-2">
        <p class="text-sm text-n-slate-11">
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.CAPACITY.AUDIENCE') }}
        </p>
        <p class="mt-2 text-2xl font-semibold text-n-slate-12">
          {{ audienceCountDisplay }}
        </p>
      </div>
      <div class="p-5 border rounded-xl border-n-strong bg-n-blue-2">
        <div class="flex items-center justify-between">
          <p class="text-sm text-n-slate-11">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.CAPACITY.META_LIMIT') }}
          </p>
          <Button
            type="button"
            size="sm"
            variant="ghost"
            color="slate"
            icon="i-lucide-refresh-cw"
            :is-loading="isLoadingHealth"
            :disabled="!state.inboxId"
            @click="refreshHealth"
          />
        </div>
        <p class="mt-2 text-2xl font-semibold text-n-slate-12">
          {{ messagingLimitDisplay }}
        </p>
        <p class="mt-1 text-xs text-n-slate-11">
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.CAPACITY.DESCRIPTION') }}
        </p>
      </div>
    </section>
    <div class="flex items-center justify-between gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        class="w-full"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CANCEL')"
        @click="emit('cancel')"
      /><Button
        type="submit"
        class="w-full"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CREATE')"
        :is-loading="formState.uiFlags.value.isCreating"
        :disabled="isSubmitDisabled"
      />
    </div>
  </form>
</template>
