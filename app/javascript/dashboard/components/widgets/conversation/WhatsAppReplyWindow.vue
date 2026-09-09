<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import InboxesAPI from 'dashboard/api/inboxes';

const props = defineProps({
  conversation: { type: Object, required: true },
  inboxId: { type: Number, required: true },
  template: { type: Object, default: null },
  onSend: { type: Function, required: true },
  isOpen: { type: Boolean, required: true },
  isReplyMode: { type: Boolean, required: true },
  showOpenBanner: { type: Boolean, default: true },
  countdown: { type: String, required: true },
  showResumption: { type: Boolean, required: true },
});
const { t } = useI18n();
const TEMPLATE_NAME = 'appointment_reminder';
const TEMPLATE_LANGUAGE = 'ar';
const TEMPLATE_VALUE = 'الموافقة';
const TIME_SEPARATOR = ':';
const TEMPLATE_BODY =
  'تذكير: سيقوم الموظف لدينا بالتحدث اليكم بعد {{1}} من طرفكم.';
const localTemplateStatus = ref('');
const loading = ref(false);
const error = ref('');
const countdownParts = computed(() => props.countdown.split(':'));

const templateStatus = computed(() =>
  (
    localTemplateStatus.value ||
    props.template?.status ||
    'missing'
  ).toLowerCase()
);
const latestRequest = computed(() => {
  const messages = props.conversation.messages || [];
  const lastIncomingAt = messages
    .filter(message => message.message_type === 0 && !message.private)
    .reduce(
      (latest, message) => Math.max(latest, message.created_at),
      props.conversation.created_at || 0
    );

  return messages
    .filter(message => {
      const template =
        message.additional_attributes?.template_params ||
        message.templateParams;
      return (
        message.message_type === 1 &&
        !message.private &&
        message.created_at > lastIncomingAt &&
        template?.name === TEMPLATE_NAME &&
        template?.language === TEMPLATE_LANGUAGE
      );
    })
    .sort((first, second) => second.id - first.id)[0];
});
const awaitingReply = computed(
  () => latestRequest.value && latestRequest.value.status !== 'failed'
);
const templateIsApproved = computed(
  () =>
    templateStatus.value === 'approved' &&
    props.template?.category?.toLowerCase() === 'utility'
);
const canStart = computed(
  () => templateStatus.value === 'missing' || templateIsApproved.value
);
const statusText = computed(() => {
  if (latestRequest.value?.status === 'failed')
    return t('CONVERSATION.WHATSAPP_WINDOW.FAILED');
  if (awaitingReply.value) {
    return ['delivered', 'read'].includes(latestRequest.value.status)
      ? t('CONVERSATION.WHATSAPP_WINDOW.DELIVERED')
      : t('CONVERSATION.WHATSAPP_WINDOW.SENT');
  }
  if (templateStatus.value === 'pending')
    return t('CONVERSATION.WHATSAPP_WINDOW.TEMPLATE_PENDING');
  if (templateStatus.value !== 'missing' && !templateIsApproved.value)
    return t('CONVERSATION.WHATSAPP_WINDOW.TEMPLATE_UNAVAILABLE');
  return t('CONVERSATION.WHATSAPP_WINDOW.EXPIRED');
});

const createTemplate = async () => {
  const formData = new FormData();
  formData.append(
    'template',
    JSON.stringify({
      name: TEMPLATE_NAME,
      language: TEMPLATE_LANGUAGE,
      category: 'UTILITY',
      parameter_format: 'POSITIONAL',
      template_format: 'standard',
      header_type: 'none',
      header_text: '',
      header_example: '',
      body: TEMPLATE_BODY,
      body_examples: ['2025-12-31'],
      footer: '',
      buttons: [],
    })
  );
  const { data } = await InboxesAPI.createMessageTemplate(
    props.inboxId,
    formData
  );
  localTemplateStatus.value = data.template?.status || 'pending';
};

const startConversation = async () => {
  loading.value = true;
  error.value = '';
  try {
    if (templateStatus.value === 'missing') {
      await createTemplate();
      return;
    }
    if (!templateIsApproved.value) return;

    const message = TEMPLATE_BODY.replace('{{1}}', TEMPLATE_VALUE);
    await props.onSend({
      message,
      pendingMessageContent: message,
      templateParams: {
        name: TEMPLATE_NAME,
        category: 'UTILITY',
        language: TEMPLATE_LANGUAGE,
        content_mode: 'raw_template',
        processed_params: { body: { 1: TEMPLATE_VALUE } },
      },
    });
  } catch (exception) {
    error.value =
      exception.response?.data?.error ||
      t('CONVERSATION.WHATSAPP_WINDOW.ERROR');
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div
    v-if="showOpenBanner && isOpen && isReplyMode"
    class="mx-3 mt-2 flex items-center justify-center gap-2 rounded-lg bg-green-100 px-3 py-2 text-sm text-green-900 dark:bg-green-900 dark:text-green-100"
  >
    <span class="i-lucide-clock size-4" aria-hidden="true" />
    <span>{{ t('CONVERSATION.WHATSAPP_WINDOW.OPEN') }}</span>
    <span dir="ltr" class="flex items-center font-semibold tabular-nums">
      <template v-for="(part, index) in countdownParts" :key="index">
        <Transition
          mode="out-in"
          enter-active-class="motion-safe:transition motion-safe:duration-150"
          enter-from-class="motion-safe:opacity-0 motion-safe:translate-y-1"
          enter-to-class="opacity-100 translate-y-0"
        >
          <span :key="part" class="inline-block w-5 text-center">
            {{ part }}
          </span>
        </Transition>
        <span v-if="index < countdownParts.length - 1">
          {{ TIME_SEPARATOR }}
        </span>
      </template>
    </span>
  </div>
  <div
    v-else-if="showResumption"
    class="flex min-h-[12rem] flex-col items-center justify-center gap-3 p-5 text-center"
  >
    <span
      class="i-lucide-message-circle-plus size-8 text-n-slate-11"
      aria-hidden="true"
    />
    <p class="m-0 text-sm text-n-slate-12" role="status">
      {{ statusText }}
    </p>
    <p
      v-if="error || latestRequest?.external_error"
      class="m-0 text-sm text-n-ruby-11"
      role="alert"
    >
      {{ error || latestRequest.external_error }}
    </p>
    <Button
      v-if="!awaitingReply"
      lg
      :label="t('CONVERSATION.WHATSAPP_WINDOW.START')"
      :disabled="loading || !canStart"
      :is-loading="loading"
      icon="i-lucide-message-circle-plus"
      @click="startConversation"
    />
  </div>
</template>
