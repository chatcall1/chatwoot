<script setup>
import { computed, ref } from 'vue';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import { ConnectionMode, VueFlow } from '@vue-flow/core';
import FlowEdge from '../components/edges/FlowEdge.vue';
import InteractiveButtonNode from '../components/nodes/InteractiveButtonNode.vue';
import InteractiveListNode from '../components/nodes/InteractiveListNode.vue';
import InteractiveNode from '../components/nodes/InteractiveNode.vue';
import MessageNode from '../components/nodes/MessageNode.vue';
import TriggerNode from '../components/nodes/TriggerNode.vue';
import ConditionNode from '../components/nodes/ConditionNode.vue';
import MetaMessageNode from '../components/nodes/MetaMessageNode.vue';
import NodeSettingsPanel from '../components/NodeSettingsPanel.vue';
import ExecutionHistoryDialog from '../components/ExecutionHistoryDialog.vue';
import ConnectionNodeMenu from '../components/ConnectionNodeMenu.vue';
import PlatformBadge from '../components/PlatformBadge.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import { ACTION_NODE_OPTIONS, NODE_TYPES } from '../domain/constants';
import { useFlowEditor } from '../composables/useFlowEditor';

const props = defineProps({ flow: { type: Object, required: true } });
const emit = defineEmits(['close']);

const {
  draft,
  nodes,
  edges,
  selectedNode,
  settingsNode,
  settingsNodeId,
  saveState,
  publishState,
  errorMessage,
  edgeDefaults,
  connectionMenu,
  addNode,
  addDroppedNode,
  addConnectedNode,
  closeConnectionMenu,
  connect,
  startConnection,
  endConnection,
  selectNode,
  configureNode,
  clearSelection,
  updateSelectedNode,
  duplicateSelected,
  duplicateNode,
  deleteSelected,
  deleteNode,
  deleteEdge,
  markDirty,
  save,
  publish,
  unpublish,
  close,
  fitCanvas,
} = useFlowEditor(props.flow, emit);
const showExecutionHistory = ref(false);
const availableNodeOptions = computed(() =>
  ACTION_NODE_OPTIONS.filter(
    option =>
      !option.platform || draft.value.platforms.includes(option.platform)
  )
);
const dragMime = 'application/x-flow-node';
const startNodeDrag = (event, type) => {
  event.dataTransfer.setData(dragMime, type);
  event.dataTransfer.effectAllowed = 'copy';
};
const dropNode = event => {
  const type = event.dataTransfer.getData(dragMime);
  if (!availableNodeOptions.value.some(option => option.type === type)) return;

  addDroppedNode(type, { x: event.clientX, y: event.clientY });
};
const clearCanvasSelection = () => {
  clearSelection();
  closeConnectionMenu();
};
</script>

<template>
  <div
    class="flex h-full min-h-0 flex-col overflow-hidden bg-n-background text-n-slate-12"
  >
    <header
      class="flex h-16 shrink-0 items-center justify-between border-b border-n-weak bg-n-background px-4"
    >
      <div class="flex min-w-0 items-center gap-3">
        <button
          class="flow-icon-btn"
          :aria-label="$t('FLOW_BUILDER.EDITOR.BACK')"
          @click="close"
        >
          <span class="i-lucide-arrow-right size-4" />
        </button>
        <div class="min-w-0">
          <InlineInput
            v-model="draft.name"
            custom-input-class="truncate font-medium"
            maxlength="80"
            @input="markDirty"
          />
          <p class="font-mono text-[10px] text-n-slate-9">
            {{ draft.reference }}
          </p>
        </div>
      </div>

      <div class="hidden items-center gap-1.5 md:flex">
        <PlatformBadge
          v-for="platform in draft.platforms"
          :key="platform"
          :platform="platform"
        />
      </div>

      <div class="flex items-center gap-2">
        <span
          class="me-2 text-xs"
          :class="saveState === 'saved' ? 'text-n-slate-9' : 'text-amber-400'"
        >
          {{
            saveState === 'saved'
              ? $t('FLOW_BUILDER.EDITOR.SAVED')
              : $t('FLOW_BUILDER.EDITOR.UNSAVED')
          }}
        </span>
        <button class="flow-btn" type="button" @click="fitCanvas">
          <span class="i-lucide-scan size-4" />
          <span class="hidden sm:inline">{{
            $t('FLOW_BUILDER.EDITOR.FIT')
          }}</span>
        </button>
        <button class="flow-btn flow-btn-primary" type="button" @click="save">
          <span class="i-lucide-save size-4" />
          {{ $t('FLOW_BUILDER.EDITOR.SAVE') }}
        </button>
        <button class="flow-btn" type="button" @click="publish">
          <span class="i-lucide-send size-4" />
          {{
            publishState === 'published'
              ? $t('FLOW_BUILDER.EDITOR.REPUBLISH')
              : $t('FLOW_BUILDER.EDITOR.PUBLISH')
          }}
        </button>
        <button
          v-if="publishState === 'published'"
          class="flow-btn"
          type="button"
          draggable="true"
          @click="unpublish"
        >
          <span class="i-lucide-circle-pause size-4" />
          {{ $t('FLOW_BUILDER.EDITOR.DISABLE') }}
        </button>
        <button
          class="flow-icon-btn"
          type="button"
          :disabled="!draft.id"
          :aria-label="$t('FLOW_BUILDER.EDITOR.EXECUTIONS')"
          @click="showExecutionHistory = true"
        >
          <span class="i-lucide-history size-4" />
        </button>
      </div>
    </header>

    <div
      v-if="errorMessage"
      class="border-b border-red-900 bg-red-950/40 px-4 py-2 text-sm text-red-300"
    >
      {{ errorMessage }}
    </div>

    <div class="relative flex min-h-0 flex-1">
      <aside
        class="absolute bottom-3 left-3 top-3 z-20 flex w-16 flex-col items-center overflow-y-auto rounded-xl border border-n-weak bg-n-background/95 px-2 py-3 shadow-xl backdrop-blur lg:w-48 lg:items-stretch"
      >
        <p
          class="mb-3 hidden px-2 text-[10px] font-semibold uppercase tracking-wider text-n-slate-9 lg:block"
        >
          {{ $t('FLOW_BUILDER.EDITOR.MESSAGE_NODES') }}
        </p>
        <button
          v-for="option in availableNodeOptions"
          :key="option.type"
          type="button"
          draggable="true"
          class="mb-2 flex items-center justify-center gap-3 rounded-xl p-3 text-n-slate-11 transition hover:bg-n-alpha-2 hover:text-n-slate-12 lg:justify-start"
          :title="option.label"
          @dragstart="startNodeDrag($event, option.type)"
          @click="addNode(option.type)"
        >
          <span class="size-5 shrink-0" :class="[option.icon]" />
          <span class="hidden text-sm lg:inline">{{ option.label }}</span>
        </button>

        <div class="mt-auto border-t border-n-weak pt-3">
          <button
            class="mb-1 flex w-full items-center justify-center gap-3 rounded-xl p-3 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12 lg:justify-start"
            :disabled="
              !selectedNode || selectedNode.type === NODE_TYPES.TRIGGER
            "
            @click="duplicateSelected"
          >
            <span class="i-lucide-copy size-5" />
            <span class="hidden text-sm lg:inline">
              {{ $t('FLOW_BUILDER.EDITOR.DUPLICATE_NODE') }}
            </span>
          </button>
          <button
            class="flex w-full items-center justify-center gap-3 rounded-xl p-3 text-n-slate-11 hover:bg-red-950 hover:text-red-400 disabled:opacity-30 lg:justify-start"
            :disabled="
              !selectedNode || selectedNode.type === NODE_TYPES.TRIGGER
            "
            @click="deleteSelected"
          >
            <span class="i-lucide-trash-2 size-5" />
            <span class="hidden text-sm lg:inline">
              {{ $t('FLOW_BUILDER.EDITOR.DELETE_NODE') }}
            </span>
          </button>
        </div>
      </aside>

      <section
        class="relative min-w-0 flex-1 bg-black"
        dir="ltr"
        @dragover.prevent
        @drop.prevent="dropNode"
      >
        <VueFlow
          v-model:nodes="nodes"
          v-model:edges="edges"
          class="bg-black"
          :default-edge-options="edgeDefaults"
          :connection-mode="ConnectionMode.Loose"
          :delete-key-code="null"
          :min-zoom="0.2"
          :max-zoom="2"
          :default-viewport="{ x: 0, y: 0, zoom: 1 }"
          @connect="connect"
          @connect-start="startConnection"
          @connect-end="endConnection"
          @node-click="selectNode"
          @node-double-click="configureNode"
          @pane-click="clearCanvasSelection"
          @node-drag-stop="markDirty"
        >
          <Background pattern-color="#27272a" :gap="24" :size="1" />
          <Controls position="bottom-right" />
          <template #node-trigger="nodeProps">
            <TriggerNode v-bind="nodeProps" />
          </template>
          <template #node-text="nodeProps">
            <MessageNode
              v-bind="nodeProps"
              node-type="text"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-image="nodeProps">
            <MessageNode
              v-bind="nodeProps"
              node-type="image"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-video="nodeProps">
            <MessageNode
              v-bind="nodeProps"
              node-type="video"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-document="nodeProps">
            <MessageNode
              v-bind="nodeProps"
              node-type="document"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-audio="nodeProps">
            <MessageNode
              v-bind="nodeProps"
              node-type="audio"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-interactive="nodeProps">
            <InteractiveNode
              v-bind="nodeProps"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-interactive_button="nodeProps">
            <InteractiveButtonNode
              v-bind="nodeProps"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-interactive_list="nodeProps">
            <InteractiveListNode
              v-bind="nodeProps"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-condition="nodeProps">
            <ConditionNode
              v-bind="nodeProps"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-location="nodeProps">
            <MetaMessageNode
              v-bind="nodeProps"
              node-type="location"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-location_request="nodeProps">
            <MetaMessageNode
              v-bind="nodeProps"
              node-type="location_request"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-contact="nodeProps">
            <MetaMessageNode
              v-bind="nodeProps"
              node-type="contact"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-sticker="nodeProps">
            <MetaMessageNode
              v-bind="nodeProps"
              node-type="sticker"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-reaction="nodeProps">
            <MetaMessageNode
              v-bind="nodeProps"
              node-type="reaction"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-cta_url="nodeProps">
            <MetaMessageNode
              v-bind="nodeProps"
              node-type="cta_url"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #node-carousel="nodeProps">
            <MetaMessageNode
              v-bind="nodeProps"
              node-type="carousel"
              @duplicate="duplicateNode(nodeProps.id)"
              @delete="deleteNode(nodeProps.id)"
            />
          </template>
          <template #edge-flow="edgeProps">
            <FlowEdge v-bind="edgeProps" @delete="deleteEdge" />
          </template>
        </VueFlow>
      </section>

      <ConnectionNodeMenu
        v-if="connectionMenu"
        :menu="connectionMenu"
        :options="availableNodeOptions"
        @select="addConnectedNode"
        @close="closeConnectionMenu"
      />

      <NodeSettingsPanel
        :node="settingsNode"
        @update="updateSelectedNode"
        @close="settingsNodeId = null"
      />
    </div>

    <ExecutionHistoryDialog
      v-if="draft.id"
      :open="showExecutionHistory"
      :flow-id="draft.id"
      @close="showExecutionHistory = false"
    />
  </div>
</template>
