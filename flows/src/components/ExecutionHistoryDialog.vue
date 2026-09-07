<script setup>
import { ref, watch } from 'vue';
import AppDialog from './AppDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { flowRepository } from '../repositories/flowRepository';

const props = defineProps({
  open: { type: Boolean, default: false },
  flowId: { type: Number, required: true },
});
defineEmits(['close']);

const executions = ref([]);
const loading = ref(false);
const errorMessage = ref('');
const retryingDeliveryId = ref(null);
const title = 'سجل التنفيذ';
const description = 'آخر 50 عملية تشغيل ومحاولات تسليم الرسائل.';
const refreshLabel = 'تحديث';
const emptyLabel = 'لم يُشغّل هذا البوت حتى الآن.';
const attemptLabel = 'المحاولات:';
const loadingLabel = 'جارٍ تحميل السجل...';
const messageIdLabel = 'معرّف الرسالة:';
const providerIdLabel = 'معرّف المزود:';
const lastAttemptLabel = 'آخر محاولة:';
const retryLabel = 'أعد الآن';
const retryScheduledLabel = 'إعادة المحاولة مجدولة';
const detailSeparator = '—';

const statusLabels = {
  pending: 'قيد الانتظار',
  running: 'يعمل',
  completed: 'مكتمل',
  failed: 'فشل',
  awaiting_input: 'بانتظار اختيار العميل',
  enqueued: 'أُرسل للطابور',
  accepted: 'قبله المزود',
  delivered: 'وصل',
  read: 'قُرئ',
  exact_match: 'تطابق الكلمة',
  no_match: 'رسالة الترحيب',
};

const nodeTypeLabels = {
  text: 'رسالة نصية',
  image: 'صورة',
  video: 'فيديو',
  document: 'مستند',
  audio: 'صوت',
  interactive: 'رسالة تفاعلية',
  condition: 'شرط',
  location: 'موقع',
  location_request: 'طلب موقع',
  contact: 'جهة اتصال',
  sticker: 'ملصق',
  reaction: 'تفاعل',
  cta_url: 'زر رابط',
  carousel: 'معرض وسائط',
};
const conditionResultLabel = matched =>
  matched ? 'تحقق الشرط' : 'لم يتحقق الشرط';

const load = async () => {
  loading.value = true;
  try {
    executions.value = await flowRepository.executions(props.flowId);
    errorMessage.value = '';
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message ||
      error.response?.data?.error ||
      error.message;
  } finally {
    loading.value = false;
  }
};

const formatDate = value =>
  new Intl.DateTimeFormat('ar', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));

const retryDelivery = async delivery => {
  retryingDeliveryId.value = delivery.id;
  try {
    await flowRepository.retryDelivery(props.flowId, delivery.id);
    await load();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message ||
      error.response?.data?.error ||
      error.message;
  } finally {
    retryingDeliveryId.value = null;
  }
};

watch(
  () => props.open,
  value => {
    if (value) load();
  }
);
</script>

<template>
  <AppDialog
    :open="open"
    :title="title"
    :description="description"
    :confirm-label="refreshLabel"
    :confirm-disabled="loading"
    @close="$emit('close')"
    @confirm="load"
  >
    <p v-if="errorMessage" class="text-sm text-n-ruby-11">
      {{ errorMessage }}
    </p>
    <p v-else-if="loading" class="text-sm text-n-slate-10">
      {{ loadingLabel }}
    </p>
    <p v-else-if="!executions.length" class="text-sm text-n-slate-10">
      {{ emptyLabel }}
    </p>
    <div v-else class="max-h-96 space-y-3 overflow-y-auto">
      <article
        v-for="execution in executions"
        :key="execution.id"
        class="rounded-xl border border-n-weak p-3"
      >
        <div class="flex items-center justify-between gap-3">
          <span class="text-sm font-medium text-n-slate-12">
            {{ statusLabels[execution.triggerKind] || execution.triggerKind }}
          </span>
          <span class="text-xs text-n-slate-9">
            {{ formatDate(execution.createdAt) }}
          </span>
        </div>
        <p class="mt-1 text-xs text-n-slate-10">
          {{ statusLabels[execution.status] || execution.status }}
        </p>
        <div
          v-for="(result, nodeId) in execution.conditionResults"
          :key="nodeId"
          class="mt-2 flex items-center justify-between rounded-lg bg-n-alpha-2 p-2 text-xs"
        >
          <span class="text-n-slate-11">{{ nodeTypeLabels.condition }}</span>
          <span :class="result.matched ? 'text-n-teal-11' : 'text-n-ruby-11'">
            {{ conditionResultLabel(result.matched) }}
          </span>
        </div>
        <div
          v-for="delivery in execution.deliveries"
          :key="delivery.id"
          class="mt-2 rounded-lg bg-n-alpha-2 p-2 text-xs text-n-slate-11"
        >
          <div class="flex items-start justify-between gap-2">
            <span class="min-w-0">
              <span class="block font-medium text-n-slate-12">
                {{ nodeTypeLabels[delivery.nodeType] || delivery.nodeType }}
              </span>
              <span v-if="delivery.nodeLabel" class="block truncate">
                {{ delivery.nodeLabel }}
              </span>
            </span>
            <span>{{ attemptLabel }} {{ delivery.attemptCount }}</span>
          </div>
          <div class="mt-2 flex items-center justify-between gap-3">
            <span>{{ statusLabels[delivery.status] || delivery.status }}</span>
            <Button
              v-if="delivery.canRetry"
              :label="retryLabel"
              icon="i-lucide-rotate-ccw"
              size="xs"
              variant="outline"
              color="slate"
              :is-loading="retryingDeliveryId === delivery.id"
              @click="retryDelivery(delivery)"
            />
          </div>
          <dl class="mt-2 grid gap-1 text-n-slate-10">
            <div v-if="delivery.messageId" class="flex gap-1">
              <dt>{{ messageIdLabel }}</dt>
              <dd class="font-mono">{{ delivery.messageId }}</dd>
            </div>
            <div v-if="delivery.providerMessageId" class="flex min-w-0 gap-1">
              <dt class="shrink-0">{{ providerIdLabel }}</dt>
              <dd class="truncate font-mono">
                {{ delivery.providerMessageId }}
              </dd>
            </div>
            <div v-if="delivery.lastAttemptAt" class="flex gap-1">
              <dt>{{ lastAttemptLabel }}</dt>
              <dd>{{ formatDate(delivery.lastAttemptAt) }}</dd>
            </div>
          </dl>
          <p v-if="delivery.retryScheduledAt" class="mt-2 text-n-amber-11">
            {{ retryScheduledLabel }} {{ detailSeparator }}
            {{ formatDate(delivery.retryScheduledAt) }}
          </p>
          <p v-if="delivery.lastError" class="mt-1 break-words text-n-ruby-11">
            {{ delivery.lastError }}
          </p>
        </div>
      </article>
    </div>
  </AppDialog>
</template>
