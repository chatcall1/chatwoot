import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { MarkerType, useVueFlow } from '@vue-flow/core';
import { useAlert } from 'dashboard/composables';
import { NODE_TYPES } from '../domain/constants';
import {
  createActionNode,
  createInteractiveChildNode,
} from '../domain/flowFactory';
import { normalizeTriggerData } from '../domain/triggerRules';
import { flowRepository } from '../repositories/flowRepository';
import { generateId } from '../utils/id';
import { cloneJson } from '../utils/json';

const normalizeContactData = data => ({
  ...data,
  name: {
    formatted_name: '',
    first_name: '',
    middle_name: '',
    last_name: '',
    prefix: '',
    suffix: '',
    ...data.name,
  },
  org: { company: '', department: '', title: '', ...data.org },
  phones: data.phones || [],
  emails: data.emails || [],
  urls: data.urls || [],
  addresses: data.addresses || [],
});

const normalizeCarouselData = data => ({
  ...data,
  buttonType: data.buttonType || 'url',
  cards: (data.cards || []).map(card => ({
    ...card,
    id: card.id || generateId(),
    replies: (card.replies || []).map(reply => ({
      ...reply,
      id: reply.id || generateId(),
    })),
  })),
});

export const useFlowEditor = (flow, emit) => {
  const { t } = useI18n();
  const draft = ref(cloneJson(flow));
  draft.value.graph.nodes.forEach(node => {
    if (node.type === NODE_TYPES.TRIGGER) {
      node.data = normalizeTriggerData(node.data);
    } else if (node.type === NODE_TYPES.INTERACTIVE) {
      node.data = { interactionType: null, ...node.data };
    } else if (node.type === NODE_TYPES.INTERACTIVE_BUTTON) {
      node.data = { replyId: node.id, ...node.data };
    } else if (node.type === NODE_TYPES.INTERACTIVE_LIST) {
      const legacyRows = (node.data.rows || []).map(row => ({
        description: '',
        ...row,
      }));
      node.data = {
        ...node.data,
        sections: node.data.sections?.map(section => ({
          ...section,
          rows: section.rows.map(row => ({ description: '', ...row })),
        })) || [
          {
            id: generateId(),
            title: node.data.sectionTitle || 'الخيارات',
            rows: legacyRows,
          },
        ],
      };
    } else if (node.type === NODE_TYPES.CONTACT) {
      node.data = normalizeContactData(node.data);
    } else if (node.type === NODE_TYPES.CAROUSEL) {
      node.data = normalizeCarouselData(node.data);
    }
  });

  const nodes = ref(draft.value.graph.nodes);
  const edges = ref(draft.value.graph.edges);
  const selectedNodeId = ref(null);
  const settingsNodeId = ref(null);
  const saveState = ref('saved');
  const publishState = ref(draft.value.status);
  const errorMessage = ref('');
  const connectionOrigin = ref(null);
  const connectionStartPoint = ref(null);
  const connectionCompleted = ref(false);
  const connectionMenu = ref(null);
  const { fitView, screenToFlowCoordinate } = useVueFlow();

  const selectedNode = computed(() =>
    nodes.value.find(node => node.id === selectedNodeId.value)
  );
  const settingsNode = computed(() =>
    nodes.value.find(node => node.id === settingsNodeId.value)
  );
  const edgeDefaults = {
    type: 'flow',
    markerEnd: MarkerType.ArrowClosed,
  };

  const markDirty = () => {
    saveState.value = 'dirty';
    errorMessage.value = '';
  };

  const removeInteractiveBranch = (parentId, handleId) => {
    const removedIds = new Set(
      edges.value
        .filter(
          edge => edge.source === parentId && edge.sourceHandle === handleId
        )
        .map(edge => edge.target)
    );
    nodes.value = nodes.value.filter(item => !removedIds.has(item.id));
    edges.value = edges.value.filter(
      edge => !removedIds.has(edge.source) && !removedIds.has(edge.target)
    );
  };

  const addNodeAt = (type, position) => {
    const node = createActionNode(type, nodes.value.length);
    node.position = position;
    nodes.value.push(node);
    selectedNodeId.value = node.id;
    settingsNodeId.value = null;
    markDirty();
    return node;
  };

  const addNode = type =>
    addNodeAt(
      type,
      screenToFlowCoordinate({
        x: window.innerWidth / 2,
        y: window.innerHeight / 2,
      })
    );

  const addDroppedNode = (type, point) =>
    addNodeAt(type, screenToFlowCoordinate(point));

  const connect = connection => {
    const sourceNode = nodes.value.find(node => node.id === connection.source);
    const isInteractiveChoice =
      sourceNode?.type === NODE_TYPES.INTERACTIVE &&
      ['buttons', 'list'].includes(connection.sourceHandle);
    const hasNextEdge = edges.value.some(
      edge => edge.source === connection.source && edge.sourceHandle === 'next'
    );
    const duplicate = edges.value.some(
      edge =>
        edge.source === connection.source && edge.target === connection.target
    );
    const hasSourcePath = edges.value.some(
      edge =>
        edge.source === connection.source &&
        edge.sourceHandle === connection.sourceHandle
    );

    if (
      isInteractiveChoice ||
      (sourceNode?.type === NODE_TYPES.INTERACTIVE &&
        connection.sourceHandle === 'next' &&
        hasNextEdge) ||
      duplicate ||
      hasSourcePath ||
      connection.source === connection.target
    ) {
      return;
    }

    connectionCompleted.value = true;
    edges.value.push({
      ...connection,
      ...edgeDefaults,
      id: `edge-${generateId()}`,
    });
    markDirty();
  };

  const startConnection = params => {
    connectionMenu.value = null;
    connectionOrigin.value = params;
    connectionStartPoint.value = params.event
      ? { x: params.event.clientX, y: params.event.clientY }
      : null;
    connectionCompleted.value = false;
  };

  const endConnection = event => {
    const origin = connectionOrigin.value;
    const startPoint = connectionStartPoint.value;
    connectionOrigin.value = null;
    connectionStartPoint.value = null;
    if (connectionCompleted.value || !origin?.nodeId) return;
    if (origin.handleType && origin.handleType !== 'source') return;

    const point = event?.changedTouches?.[0] || event;
    if (!point || typeof point.clientX !== 'number') return;
    const draggedDistance = startPoint
      ? Math.hypot(point.clientX - startPoint.x, point.clientY - startPoint.y)
      : 0;
    if (draggedDistance < 8) return;
    const position = screenToFlowCoordinate({
      x: point.clientX,
      y: point.clientY,
    });
    const parent = nodes.value.find(node => node.id === origin.nodeId);
    const isInteractiveBranch =
      parent?.type === NODE_TYPES.INTERACTIVE &&
      ['buttons', 'list'].includes(origin.handleId);
    if (!isInteractiveBranch) {
      const sourceAlreadyConnected = edges.value.some(
        edge =>
          edge.source === origin.nodeId && edge.sourceHandle === origin.handleId
      );
      if (!sourceAlreadyConnected) {
        connectionMenu.value = {
          x: point.clientX,
          y: point.clientY,
          position,
          origin,
        };
      }
      return;
    }

    const selectedType = parent.data.interactionType;
    if (
      ['buttons', 'list'].includes(origin.handleId) &&
      selectedType &&
      selectedType !== origin.handleId
    ) {
      removeInteractiveBranch(parent.id, selectedType);
    }
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
    parent.data = { ...parent.data, interactionType: origin.handleId };
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
    markDirty();
  };

  const addConnectedNode = type => {
    const pending = connectionMenu.value;
    if (!pending) return;

    const node = addNodeAt(type, pending.position);
    edges.value.push({
      id: `edge-${generateId()}`,
      source: pending.origin.nodeId,
      sourceHandle: pending.origin.handleId,
      target: node.id,
      targetHandle: null,
      ...edgeDefaults,
    });
    connectionMenu.value = null;
  };

  const closeConnectionMenu = () => {
    connectionMenu.value = null;
  };

  const selectNode = event => {
    selectedNodeId.value = event.node.id;
  };
  const configureNode = event => {
    selectedNodeId.value = event.node.id;
    settingsNodeId.value = event.node.id;
  };
  const clearSelection = () => {
    selectedNodeId.value = null;
    settingsNodeId.value = null;
  };
  const updateSelectedNode = data => {
    const node = settingsNode.value;
    if (!node) return;
    if (
      node.type === NODE_TYPES.INTERACTIVE &&
      data.interactionType &&
      data.interactionType !== node.data.interactionType
    ) {
      const removedHandle =
        data.interactionType === 'buttons' ? 'list' : 'buttons';
      removeInteractiveBranch(node.id, removedHandle);
    }
    if (node.type === NODE_TYPES.INTERACTIVE_LIST) {
      const rowHandles = new Set(
        (data.sections || []).flatMap(section =>
          section.rows.map(row => `row:${row.id}`)
        )
      );
      edges.value = edges.value.filter(
        edge => edge.source !== node.id || rowHandles.has(edge.sourceHandle)
      );
    }
    if (node.type === NODE_TYPES.CAROUSEL) {
      const replyHandles = new Set(
        (data.cards || []).flatMap(card =>
          (card.replies || []).map(reply => `reply:${reply.id}`)
        )
      );
      edges.value = edges.value.filter(
        edge =>
          edge.source !== node.id ||
          !edge.sourceHandle?.startsWith('reply:') ||
          replyHandles.has(edge.sourceHandle)
      );
    }
    node.data =
      node.type === NODE_TYPES.TRIGGER ? normalizeTriggerData(data) : data;
    markDirty();
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
    markDirty();
  };

  const deleteSelected = () => {
    const node = selectedNode.value;
    if (!node || node.type === NODE_TYPES.TRIGGER) return;
    const dependentIds = new Set([node.id]);
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
    nodes.value = nodes.value.filter(item => !dependentIds.has(item.id));
    edges.value = edges.value.filter(
      edge => !dependentIds.has(edge.source) && !dependentIds.has(edge.target)
    );
    clearSelection();
    markDirty();
  };

  const duplicateNode = nodeId => {
    selectedNodeId.value = nodeId;
    duplicateSelected();
  };

  const deleteNode = nodeId => {
    selectedNodeId.value = nodeId;
    deleteSelected();
  };

  const deleteEdge = edgeId => {
    edges.value = edges.value.filter(edge => edge.id !== edgeId);
    markDirty();
  };

  const save = async () => {
    draft.value.graph = {
      nodes: nodes.value.map(node => ({
        id: node.id,
        type: node.type,
        position: node.position,
        data: node.data,
      })),
      edges: edges.value.map(edge => ({
        id: edge.id,
        type: edge.type || 'flow',
        source: edge.source,
        target: edge.target,
        sourceHandle: edge.sourceHandle || null,
        targetHandle: edge.targetHandle || null,
        markerEnd: edge.markerEnd || MarkerType.ArrowClosed,
      })),
    };
    try {
      draft.value = await flowRepository.save(draft.value);
      saveState.value = 'saved';
      errorMessage.value = '';
      return true;
    } catch (error) {
      errorMessage.value =
        error.response?.data?.message ||
        error.response?.data?.errors ||
        error.message;
      return false;
    }
  };

  const close = async () => {
    if (saveState.value === 'dirty') {
      if (!(await save())) return;
      useAlert(t('FLOW_BUILDER.EDITOR.DRAFT_SAVED_ON_EXIT'));
    }
    emit('close');
  };
  const publish = async () => {
    if (saveState.value === 'dirty' && !(await save())) return false;

    try {
      draft.value = await flowRepository.publish(draft.value.id);
      publishState.value = draft.value.status;
      errorMessage.value = '';
      return true;
    } catch (error) {
      errorMessage.value =
        error.response?.data?.message ||
        error.response?.data?.error ||
        error.message;
      return false;
    }
  };
  const unpublish = async () => {
    try {
      draft.value = await flowRepository.unpublish(draft.value.id);
      publishState.value = draft.value.status;
      errorMessage.value = '';
      return true;
    } catch (error) {
      errorMessage.value =
        error.response?.data?.message ||
        error.response?.data?.error ||
        error.message;
      return false;
    }
  };
  const fitCanvas = async () => {
    await nextTick();
    fitView({ padding: 0.25, duration: 300 });
  };

  return {
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
  };
};
