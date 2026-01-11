import { vi } from "vitest";

// Mock chrome APIs
const mockStorage: Record<string, Record<string, unknown>> = {
  local: {},
  session: {},
};

globalThis.chrome = {
  storage: {
    local: {
      get: vi.fn((keys) => {
        if (typeof keys === "string") {
          return Promise.resolve({ [keys]: mockStorage.local[keys] });
        }
        const result: Record<string, unknown> = {};
        for (const key of keys) {
          result[key] = mockStorage.local[key];
        }
        return Promise.resolve(result);
      }),
      set: vi.fn((items) => {
        Object.assign(mockStorage.local, items);
        return Promise.resolve();
      }),
      remove: vi.fn((keys) => {
        const keysArray = typeof keys === "string" ? [keys] : keys;
        for (const key of keysArray) {
          delete mockStorage.local[key];
        }
        return Promise.resolve();
      }),
      clear: vi.fn(() => {
        mockStorage.local = {};
        return Promise.resolve();
      }),
    },
    session: {
      get: vi.fn((keys) => {
        if (typeof keys === "string") {
          return Promise.resolve({ [keys]: mockStorage.session[keys] });
        }
        const result: Record<string, unknown> = {};
        for (const key of keys) {
          result[key] = mockStorage.session[key];
        }
        return Promise.resolve(result);
      }),
      set: vi.fn((items) => {
        Object.assign(mockStorage.session, items);
        return Promise.resolve();
      }),
      remove: vi.fn((keys) => {
        const keysArray = typeof keys === "string" ? [keys] : keys;
        for (const key of keysArray) {
          delete mockStorage.session[key];
        }
        return Promise.resolve();
      }),
      clear: vi.fn(() => {
        mockStorage.session = {};
        return Promise.resolve();
      }),
    },
  },
  runtime: {
    sendMessage: vi.fn(),
    onMessage: {
      addListener: vi.fn(),
    },
  },
} as unknown as typeof chrome;

// Helper to reset storage between tests
export const resetMockStorage = () => {
  mockStorage.local = {};
  mockStorage.session = {};
};
