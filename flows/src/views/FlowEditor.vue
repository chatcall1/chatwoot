<script setup>
import { computed, nextTick, ref } from 'vue';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import {
  ConnectionMode,
  MarkerType,
  VueFlow,
  useVueFlow,
} from '@vue-flow/core';
import FlowEdge from '../components/edges/FlowEdge.vue';
import InteractiveButtonNode from '../components/nodes/InteractiveButtonNode.vue';
import InteractiveListNode from '../components/nodes/InteractiveListNode.vue';
import InteractiveNode from '../components/nodes/InteractiveNode.vue';
import MessageNode from '../components/nodes/MessageNode.vue';
import TriggerNode from '../components/nodes/TriggerNode.vue';
import NodeSettingsPanel from '../components/NodeSettingsPanel.vue';
import PlatformBadge from '../components/PlatformBadge.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import { ACTION_NODE_OPTIONS, NODE_TYPES } from '../domain/constants';
import {
  createActionNode,
  createInteractiveChildNode,
} from '../domain/flowFactory';
import { flowRepository } from '../repositories/flowRepository';
import { generateId } from '../utils/id';
import { cloneJson } from '../utils/json';

const props = defineProps({ flow: { type: Object, required: true } });
const emit = defineEmits(['close']);

const draft = ref(cloneJson(props.flow));
const nodes = ref(draft.value.graph.nodes);
const edges = ref(draft.value.graph.edges);
const selectedNodeId = ref(null);
const settingsNodeId = ref(null);
const saveState = ref('saved');
const connectionOrigin = ref(null);
const connectionCompleted = ref(false);
const { fitView, screenToFlowCoordinate } = useVueFlow();

const selectedNode = computed(() =>
  nodes.value.find(node => node.id === selectedNodeId.value)
);
const settingsNode = computed(() =>
  nodes.value.find(node => node.id === settingsNodeId.value)
);
const availableNodeOptions = computed(() =>
  ACTION_NODE_OPTIONS.filter(
    option =>
      !option.platform || draft.value.platforms.includes(option.platform)
  )
);

const edgeDefaults = {
  type: 'flow',
  markerEnd: MarkerType.ArrowClosed,
};

const addNode = type => {
  const node = createActionNode(type, nodes.value.length);
  node.position = screenToFlowCoordinate({
    x: window.innerWidth / 2,
    y: window.innerHeight / 2,
  });
  nodes.value.push(node);
  selectedNodeId.value = node.id;
  settingsNodeId.value = null;
  saveState.value = 'dirty';
};

const connect = connection => {
  const sourceNode = nodes.value.find(node => node.id === connection.source);
  if (
    sourceNode?.type === NODE_TYPES.INTERACTIVE &&
    ['buttons', 'list'].includes(connection.sourceHandle)
  ) {
    return;
  }
  if (
    sourceNode?.type === NODE_TYPES.INTERACTIVE &&
    connection.sourceHandle === 'next' &&
    edges.value.some(
      edge => edge.source === connection.source && edge.sourceHandle === 'next'
    )
  ) {
    return;
  }
  const duplicate = edges.value.some(
    edge =>
      edge.source === connection.source && edge.target === connection.target
  );
  if (duplicate || connection.source === connection.target) return;
  connectionCompleted.value = true;
  edges.value.push({
    ...connection,
    ...edgeDefaults,
    id: `edge-${generateId()}`,
  });
  saveState.value = 'dirty';
};

const startConnection = params => {
  connectionOrigin.value = params;
  connectionCompleted.value = false;
};

const connectionEndPosition = event => {
  const point = event?.changedTouches?.[0] || event;
  if (!point || typeof point.clientX !== 'number') return null;
  return screenToFlowCoordinate({ x: point.clientX, y: point.clientY });
};

const endConnection = event => {
  const origin = connectionOrigin.value;
  connectionOrigin.value = null;
  if (connectionCompleted.value || !origin?.nodeId) return;

  const parent = nodes.value.find(node => node.id === origin.nodeId);
  if (parent?.type !== NODE_TYPES.INTERACTIVE) return;

  const position = connectionEndPosition(event);
  if (!position) return;

  const childEdges = edges.value.filter(
    edge => edge.source === parent.id && edge.sourceHandle === origin.handleId
  );

  let childType;
  if (origin.handleId === 'buttons' && childEdges.length < 3) {
    childType = NODE_TYPES.INTERACTIVE_BUTTON;
  } else if (origin.handleId === 'list' && childEdges.length === 0) {
    childType = NODE_TYPES.INTERACTIVE_LIST;
  } else {
    return;
  }

  const child = createInteractiveChildNode(
    childType,
    position,
    childEdges.length
  );
  nodes.value.push(child);
  edges.value.push({
    id: `edge-${generateId()}`,
    source: parent.id,
    sourceHandle: origin.handleId,
    target: child.id,
    targetHandle: null,
    ...edgeDefaults,
  });
  selectedNodeId.value = child.id;
  saveState.value = 'dirty';
};

const selectNode = event => {
  selectedNodeId.value = event.node.id;
};

const configureNode = event => {
  selectedNodeId.value = event.node.id;
  settingsNodeId.value = event.node.id;
};

const updateSelectedNode = data => {
  const node = settingsNode.value;
  if (!node) return;
  node.data = data;
  saveState.value = 'dirty';
};

const duplicateSelected = () => {
  const node = selectedNode.value;
  if (!node || node.type === NODE_TYPES.TRIGGER) return;
  const copy = cloneJson(node);
  copy.id = generateId();
  copy.position = { x: node.position.x + 40, y: node.position.y + 40 };
  copy.selected = false;
  nodes.value.push(copy);
  selectedNodeId.value = copy.id;
  saveState.value = 'dirty';
};

const deleteSelected = () => {
  const node = selectedNode.value;
  if (!node || node.type === NODE_TYPES.TRIGGER) return;
  const dependentIds = new Set();
  if (node.type === NODE_TYPES.INTERACTIVE) {
    edges.value.forEach(edge => {
      if (
        edge.source === node.id &&
        ['buttons', 'list'].includes(edge.sourceHandle)
      ) {
        dependentIds.add(edge.target);
      }
    });
  }
  dependentIds.add(node.id);
  nodes.value = nodes.value.filter(item => !dependentIds.has(item.id));
  edges.value = edges.value.filter(
    edge => !dependentIds.has(edge.source) && !dependentIds.has(edge.target)
  );
  selectedNodeId.value = null;
  settingsNodeId.value = null;
  saveState.value = 'dirty';
};

const save = () => {
  draft.value.graph = {
    nodes: nodes.value.map(
      ({ dimensions, selected, dragging, ...node }) => node
    ),
    edges: edges.value.map(({ selected, ...edge }) => edge),
  };
  draft.value = flowRepository.save(draft.value);
  saveState.value = 'saved';
};

const close = () => {
  if (saveState.value === 'dirty') save();
  emit('close');
};

const fitCanvas = async () => {
  await nextTick();
  fitView({ padding: 0.25, duration: 300 });
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
            @input="saveState = 'dirty'"
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
      </div>
    </header>

    <div class="flex min-h-0 flex-1">
      <aside
        class="flex w-20 shrink-0 flex-col items-center border-l border-n-weak bg-n-background py-4 lg:w-56 lg:items-stretch lg:px-3"
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
          class="mb-2 flex items-center justify-center gap-3 rounded-xl p-3 text-n-slate-11 transition hover:bg-n-alpha-2 hover:text-n-slate-12 lg:justify-start"
          :title="option.label"
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

      <section class="relative min-w-0 flex-1 bg-black" dir="ltr">
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
          @pane-click="
            selectedNodeId = null;
            settingsNodeId = null;
          "
          @node-drag-stop="saveState = 'dirty'"
        >
          <Background pattern-color="#27272a" :gap="24" :size="1" />
          <Controls position="bottom-left" />
          <template #node-trigger="nodeProps">
            <TriggerNode v-bind="nodeProps" />
          </template>
          <template #node-text="nodeProps">
            <MessageNode v-bind="nodeProps" node-type="text" />
          </template>
          <template #node-image="nodeProps">
            <MessageNode v-bind="nodeProps" node-type="image" />
          </template>
          <template #node-video="nodeProps">
            <MessageNode v-bind="nodeProps" node-type="video" />
          </template>
          <template #node-document="nodeProps">
            <MessageNode v-bind="nodeProps" node-type="document" />
          </template>
          <template #node-interactive="nodeProps">
            <InteractiveNode v-bind="nodeProps" />
          </template>
          <template #node-interactive_button="nodeProps">
            <InteractiveButtonNode v-bind="nodeProps" />
          </template>
          <template #node-interactive_list="nodeProps">
            <InteractiveListNode v-bind="nodeProps" />
          </template>
          <template #edge-flow="edgeProps">
            <FlowEdge v-bind="edgeProps" />
          </template>
        </VueFlow>
      </section>

      <NodeSettingsPanel
        :node="settingsNode"
        @update="updateSelectedNode"
        @close="settingsNodeId = null"
      />
    </div>
  </div>
</template>
