export const CATEGORIES = {
  'nurse-ai': {
    title: 'Nurse + AI',
    description:
      'AI tools in nursing practice — what actually helps and what wastes a shift, written by an RN.',
    intro:
      'Honest accounts of using AI assistants on the ward. No vendor pitches.',
  },
  'ece-ai': {
    title: 'ECT + AI',
    description:
      'AI for early childhood teachers — lesson planning, parent comms, observations.',
    intro:
      'Written by a working ECT in Sydney. Real classroom examples, real iteration cycles.',
  },
  'dev-diary': {
    title: 'Dev Diary',
    description:
      'Building indie tools with AI coding assistants — the bugs, the rewrites, the things I killed.',
    intro: 'Public log of indie dev work. Failure stories included on purpose.',
  },
} as const;

export type CategoryKey = keyof typeof CATEGORIES;
