import { databaseUrlSchema } from './env';

interface TestCase {
  name: string;
  url: string;
  expectedSuccess: boolean;
  expectedErrorSubstring?: string;
}

const testCases: TestCase[] = [
  // 1. Valid PostgreSQL URLs
  {
    name: 'Valid postgresql:// URL with port and query params',
    url: 'postgresql://fake_user:fake_password@localhost:5432/discovery_uttarakhand?schema=public',
    expectedSuccess: true,
  },
  {
    name: 'Valid postgres:// URL with IPv4 host',
    url: 'postgres://fake_user:fake_password@127.0.0.1:5432/discovery_uttarakhand',
    expectedSuccess: true,
  },
  {
    name: 'Valid postgresql:// URL with domain host',
    url: 'postgresql://fake_user:fake_password@db.example.internal:5432/discovery_prod',
    expectedSuccess: true,
  },

  // 2. Malformed URLs
  {
    name: 'Malformed URL: completely invalid string',
    url: 'not-a-valid-connection-string',
    expectedSuccess: false,
    expectedErrorSubstring: 'DATABASE_URL is not a valid URL format',
  },
  {
    name: 'Malformed URL: missing scheme',
    url: '://localhost:5432/discovery_uttarakhand',
    expectedSuccess: false,
    expectedErrorSubstring: 'DATABASE_URL is not a valid URL format',
  },

  // 3. Missing hostname
  {
    name: 'Missing hostname: empty host before path',
    url: 'postgresql:///discovery_uttarakhand',
    expectedSuccess: false,
    expectedErrorSubstring: 'DATABASE_URL must include a valid hostname',
  },

  // 4. Missing database name
  {
    name: 'Missing database name: trailing slash only',
    url: 'postgresql://fake_user:fake_password@localhost:5432/',
    expectedSuccess: false,
    expectedErrorSubstring: 'DATABASE_URL must include a valid database name',
  },
  {
    name: 'Missing database name: no path component',
    url: 'postgresql://fake_user:fake_password@localhost:5432',
    expectedSuccess: false,
    expectedErrorSubstring: 'DATABASE_URL must include a valid database name',
  },

  // 5. Unsupported protocols
  {
    name: 'Unsupported protocol: mysql://',
    url: 'mysql://fake_user:fake_password@localhost:3306/discovery_uttarakhand',
    expectedSuccess: false,
    expectedErrorSubstring: "DATABASE_URL protocol must be 'postgresql:' or 'postgres:'",
  },
  {
    name: 'Unsupported protocol: http://',
    url: 'http://fake_user:fake_password@localhost:5000/discovery_uttarakhand',
    expectedSuccess: false,
    expectedErrorSubstring: "DATABASE_URL protocol must be 'postgresql:' or 'postgres:'",
  },
  {
    name: 'Unsupported protocol: mongodb://',
    url: 'mongodb://fake_user:fake_password@localhost:27017/discovery_uttarakhand',
    expectedSuccess: false,
    expectedErrorSubstring: "DATABASE_URL protocol must be 'postgresql:' or 'postgres:'",
  },
];

export function runDatabaseUrlValidationTests(): boolean {
  let passedCount = 0;
  let failedCount = 0;

  for (const tc of testCases) {
    const result = databaseUrlSchema.safeParse(tc.url);

    if (result.success !== tc.expectedSuccess) {
      console.error(`FAILED: ${tc.name} — Expected success=${tc.expectedSuccess}, got ${result.success}`);
      failedCount++;
      continue;
    }

    if (!result.success && tc.expectedErrorSubstring) {
      const errorString = JSON.stringify(result.error.format());

      // Secret Leakage Guard: Ensure simulated password was never leaked in error output
      if (errorString.includes('fake_password')) {
        console.error(`SECURITY VIOLATION: Secret leaked in error output for test: ${tc.name}`);
        failedCount++;
        continue;
      }

      if (!errorString.includes(tc.expectedErrorSubstring)) {
        console.error(
          `FAILED: ${tc.name} — Expected error message containing '${tc.expectedErrorSubstring}', got: ${errorString}`
        );
        failedCount++;
        continue;
      }
    }

    passedCount++;
    console.log(`PASS: ${tc.name}`);
  }

  console.log(`\nValidation Test Summary: ${passedCount} passed, ${failedCount} failed of ${testCases.length} tests.`);
  return failedCount === 0;
}

if (process.argv[1]?.endsWith('env.validator.test.ts') || process.argv[1]?.endsWith('env.validator.test.js')) {
  const success = runDatabaseUrlValidationTests();
  if (!success) {
    process.exit(1);
  }
}

