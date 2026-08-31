<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import AppDialog from '../components/AppDialog.vue';
import CreateFlowDialog from '../components/CreateFlowDialog.vue';
import PlatformBadge from '../components/PlatformBadge.vue';
import { createFlow, duplicateFlow } from '../domain/flowFactory';
import { flowRepository } from '../repositories/flowRepository';

const emit = defineEmits(['open']);
const store = useStore();
const inboxes = useMapGetter('inboxes/getInboxes');
const flows = ref([]);
const showCreateDialog = ref(false);
const deleteTarget = ref(null);
const importInput = ref(null);
const errorMessage = ref('');

const hasFlows = computed(() => flows.value.length > 0);
const reload = () => {
  flows.value = flowRepository.list();
};

onMounted(() => {
  reload();
  store.dispatch('inboxes/get');
});

const handleCreate = payload => {
  const flow = flowRepository.save(createFlow(payload));
  showCreateDialog.value = false;
  emit('open', flow);
};

const openCreateDialog = async () => {
  await store.dispatch('inboxes/get');
  showCreateDialog.value = true;
};

const handleDuplicate = flow => {
  flowRepository.save(duplicateFlow(flow));
  reload();
};

const handleDelete = () => {
  flowRepository.remove(deleteTarget.value.id);
  deleteTarget.value = null;
  reload();
};

const exportFlow = flow => {
  const blob = new Blob([JSON.stringify(flow, null, 2)], {
    type: 'application/json',
  });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `${flow.reference}.json`;
  link.click();
  URL.revokeObjectURL(link.href);
};

const importFlow = async event => {
  const [file] = event.target.files;
  event.target.value = '';
  if (!file) return;
  try {
    flowRepository.import(JSON.parse(await file.text()));
    errorMessage.value = '';
    reload();
  } catch (error) {
    errorMessage.value = error.message || 'تعذر استيراد الملف.';
  }
};

const formatDate = value =>
  new Intl.DateTimeFormat('ar', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
</script>

<template>
  <div class="min-h-full w-full overflow-auto py-6">
    <header class="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <p class="mb-2 text-sm font-medium text-n-brand">
          {{ $t('FLOW_BUILDER.EYEBROW') }}
        </p>
        <p class="text-sm text-n-slate-11">
          {{ $t('FLOW_BUILDER.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex gap-3">
        <input
          ref="importInput"
          type="file"
          accept="application/json"
          class="hidden"
          @change="importFlow"
        />
        <button class="flow-btn" type="button" @click="importInput.click()">
          <span class="i-lucide-upload size-4" />
          {{ $t('FLOW_BUILDER.IMPORT') }}
        </button>
        <button
          class="flow-btn flow-btn-primary"
          type="button"
          @click="openCreateDialog"
        >
          <span class="i-lucide-plus size-4" />
          {{ $t('FLOW_BUILDER.CREATE') }}
        </button>
      </div>
    </header>

    <div
      v-if="errorMessage"
      class="mb-5 flex items-center gap-2 rounded-xl border border-red-900 bg-red-950/40 p-3 text-sm text-red-300"
    >
      <span class="i-lucide-circle-alert size-4" />
      {{ errorMessage }}
    </div>

    <section
      class="overflow-hidden rounded-2xl border border-n-weak bg-n-background"
    >
      <div v-if="hasFlows" class="overflow-x-auto">
        <table class="w-full min-w-[880px] text-right text-sm">
          <thead
            class="border-b border-n-weak bg-n-alpha-2 text-xs text-n-slate-10"
          >
            <tr>
              <th class="w-14 px-4 py-4 font-medium">
                {{ $t('FLOW_BUILDER.TABLE.NUMBER') }}
              </th>
              <th class="px-4 py-4 font-medium">
                {{ $t('FLOW_BUILDER.TABLE.REFERENCE') }}
              </th>
              <th class="px-4 py-4 font-medium">
                {{ $t('FLOW_BUILDER.TABLE.NAME') }}
              </th>
              <th class="px-4 py-4 font-medium">
                {{ $t('FLOW_BUILDER.TABLE.CHANNELS') }}
              </th>
              <th class="px-4 py-4 font-medium">
                {{ $t('FLOW_BUILDER.TABLE.UPDATED') }}
              </th>
              <th class="w-48 px-4 py-4 text-center font-medium">
                {{ $t('FLOW_BUILDER.TABLE.ACTIONS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            <tr
              v-for="(flow, index) in flows"
              :key="flow.id"
              class="hover:bg-n-alpha-1"
            >
              <td class="px-4 py-4 text-n-slate-10">{{ index + 1 }}</td>
              <td class="px-4 py-4 font-mono text-xs text-n-slate-11">
                {{ flow.reference }}
              </td>
              <td class="px-4 py-4">
                <button
                  class="font-medium text-n-slate-12 hover:text-n-blue-11"
                  @click="$emit('open', flow)"
                >
                  {{ flow.name }}
                </button>
              </td>
              <td class="px-4 py-4">
                <div class="flex flex-wrap gap-1.5">
                  <PlatformBadge
                    v-for="platform in flow.platforms"
                    :key="platform"
                    :platform="platform"
                  />
                </div>
              </td>
              <td class="px-4 py-4 text-n-slate-11">
                {{ formatDate(flow.updatedAt) }}
              </td>
              <td class="px-4 py-4">
                <div class="flex justify-center gap-1">
                  <button
                    class="flow-icon-btn"
                    :title="$t('FLOW_BUILDER.ACTIONS.EDIT')"
                    :aria-label="$t('FLOW_BUILDER.ACTIONS.EDIT')"
                    @click="$emit('open', flow)"
                  >
                    <span class="i-lucide-pencil size-4" />
                  </button>
                  <button
                    class="flow-icon-btn"
                    :title="$t('FLOW_BUILDER.ACTIONS.DUPLICATE')"
                    :aria-label="$t('FLOW_BUILDER.ACTIONS.DUPLICATE')"
                    @click="handleDuplicate(flow)"
                  >
                    <span class="i-lucide-copy size-4" />
                  </button>
                  <button
                    class="flow-icon-btn"
                    :title="$t('FLOW_BUILDER.ACTIONS.EXPORT')"
                    :aria-label="$t('FLOW_BUILDER.ACTIONS.EXPORT')"
                    @click="exportFlow(flow)"
                  >
                    <span class="i-lucide-download size-4" />
                  </button>
                  <button
                    class="flow-icon-btn hover:text-red-400"
                    :title="$t('FLOW_BUILDER.ACTIONS.DELETE')"
                    :aria-label="$t('FLOW_BUILDER.ACTIONS.DELETE')"
                    @click="deleteTarget = flow"
                  >
                    <span class="i-lucide-trash-2 size-4" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div
        v-else
        class="flex min-h-96 flex-col items-center justify-center p-10 text-center"
      >
        <div
          class="mb-5 flex size-14 items-center justify-center rounded-2xl border border-n-weak bg-n-alpha-2"
        >
          <span class="i-lucide-workflow size-6 text-violet-400" />
        </div>
        <h2 class="text-lg font-medium text-n-slate-12">
          {{ $t('FLOW_BUILDER.EMPTY_TITLE') }}
        </h2>
        <p class="mt-2 max-w-md text-sm leading-6 text-n-slate-11">
          {{ $t('FLOW_BUILDER.EMPTY_DESCRIPTION') }}
        </p>
        <button
          class="flow-btn flow-btn-primary mt-6"
          @click="openCreateDialog"
        >
          {{ $t('FLOW_BUILDER.CREATE_FIRST') }}
        </button>
      </div>
    </section>

    <CreateFlowDialog
      :open="showCreateDialog"
      :inboxes="inboxes"
      @close="showCreateDialog = false"
      @create="handleCreate"
    />

    <AppDialog
      :open="Boolean(deleteTarget)"
      :title="$t('FLOW_BUILDER.DIALOG.DELETE_TITLE')"
      :description="
        deleteTarget
          ? $t('FLOW_BUILDER.DIALOG.DELETE_DESCRIPTION', {
              name: deleteTarget.name,
            })
          : ''
      "
      :confirm-label="$t('FLOW_BUILDER.DIALOG.DELETE_CONFIRM')"
      destructive
      @close="deleteTarget = null"
      @confirm="handleDelete"
    />
  </div>
</template>
