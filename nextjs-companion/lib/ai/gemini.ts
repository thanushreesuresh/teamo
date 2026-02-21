import {
  GoogleGenerativeAI,
  HarmBlockThreshold,
  HarmCategory,
  GenerationConfig,
} from '@google/generative-ai';

if (!process.env.GEMINI_API_KEY) {
  throw new Error('GEMINI_API_KEY is not set in environment variables.');
}

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/** Generation parameters — conservative temperature for emotional safety */
export const GENERATION_CONFIG: GenerationConfig = {
  temperature: 0.6,
  topP: 0.85,
  topK: 40,
  maxOutputTokens: 300,   // keep responses concise
  stopSequences: [],
};

/**
 * Safety thresholds — block anything borderline or above across all categories.
 * This covers romantic escalation, harmful advice, etc.
 */
export const SAFETY_SETTINGS = [
  {
    category: HarmCategory.HARM_CATEGORY_HARASSMENT,
    threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
    threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
    threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
    threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
  },
];

/**
 * Returns a configured Gemini 1.5 Flash model instance
 * with safety settings and system instruction applied.
 */
export function getCompanionModel(systemInstruction: string) {
  return genAI.getGenerativeModel({
    model: 'gemini-1.5-flash',
    systemInstruction,
    generationConfig: GENERATION_CONFIG,
    safetySettings: SAFETY_SETTINGS,
  });
}
