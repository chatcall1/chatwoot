import { describe, expect, it } from 'vitest';
import { createFlow } from 'flowBuilder/domain/flowFactory';

const createTemplate = templateId =>
  createFlow({
    name: 'Template test',
    platforms: ['whatsapp'],
    inboxIds: [1],
    templateId,
  }).graph;

describe('flow templates', () => {
  it('creates a complete three-button welcome graph', () => {
    const graph = createTemplate('welcome_buttons');
    const buttons = graph.nodes.filter(
      node => node.type === 'interactive_button'
    );

    expect(buttons).toHaveLength(3);
    buttons.forEach(button => {
      expect(
        graph.edges.filter(edge => edge.source === button.id)
      ).toHaveLength(1);
    });
  });

  it('creates a complete eight-row welcome list graph', () => {
    const graph = createTemplate('welcome_list');
    const list = graph.nodes.find(node => node.type === 'interactive_list');
    const rows = list.data.sections.flatMap(section => section.rows);

    expect(rows).toHaveLength(8);
    rows.forEach(row => {
      expect(
        graph.edges.filter(
          edge =>
            edge.source === list.id && edge.sourceHandle === `row:${row.id}`
        )
      ).toHaveLength(1);
    });
  });

  it.each(['exact_hours', 'exact_prices', 'exact_order', 'exact_support'])(
    'creates a connected Exact Match graph for %s',
    templateId => {
      const graph = createTemplate(templateId);
      const trigger = graph.nodes.find(node => node.type === 'trigger');

      expect(trigger.data.mode).toBe('exact_match');
      expect(trigger.data.keywords.length).toBeGreaterThan(0);
      expect(graph.edges).toHaveLength(1);
    }
  );
});
