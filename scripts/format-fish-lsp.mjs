#!/usr/bin/env node

import { spawn } from "node:child_process";
import { pathToFileURL } from "node:url";
import { basename, join, relative } from "node:path";
import { readdir, readFile, writeFile } from "node:fs/promises";

const root = process.cwd();
const check = process.argv.includes("--check");

class LspClient {
  constructor() {
    this.nextId = 1;
    this.pending = new Map();
    this.buffer = Buffer.alloc(0);
    this.process = spawn(
      "fish-lsp",
      ["start", "--stdio", "--skip-startup-logging"],
      {
        cwd: root,
        stdio: ["pipe", "pipe", "inherit"],
      },
    );

    this.process.stdout.on("data", (chunk) => this.read(chunk));
    this.process.on("error", (error) => {
      for (const { reject, timer } of this.pending.values()) {
        clearTimeout(timer);
        reject(error);
      }
      this.pending.clear();
    });
  }

  read(chunk) {
    this.buffer = Buffer.concat([this.buffer, chunk]);

    while (true) {
      const headerEnd = this.buffer.indexOf("\r\n\r\n");
      if (headerEnd < 0) {
        return;
      }

      const header = this.buffer.subarray(0, headerEnd).toString("utf8");
      const match = header.match(/Content-Length: *(\d+)/i);
      if (!match) {
        throw new Error(`Missing Content-Length header: ${header}`);
      }

      const length = Number(match[1]);
      const bodyStart = headerEnd + 4;
      const bodyEnd = bodyStart + length;
      if (this.buffer.length < bodyEnd) {
        return;
      }

      const message = JSON.parse(
        this.buffer.subarray(bodyStart, bodyEnd).toString("utf8"),
      );
      this.buffer = this.buffer.subarray(bodyEnd);
      this.handle(message);
    }
  }

  handle(message) {
    if (message.id !== undefined && message.method) {
      this.send({ jsonrpc: "2.0", id: message.id, result: null });
      return;
    }

    if (message.id === undefined) {
      return;
    }

    const pending = this.pending.get(message.id);
    if (!pending) {
      return;
    }

    clearTimeout(pending.timer);
    this.pending.delete(message.id);

    if (message.error) {
      pending.reject(new Error(message.error.message));
    } else {
      pending.resolve(message.result);
    }
  }

  send(message) {
    const body = Buffer.from(JSON.stringify(message), "utf8");
    this.process.stdin.write(`Content-Length: ${body.length}\r\n\r\n`);
    this.process.stdin.write(body);
  }

  request(method, params) {
    const id = this.nextId++;
    this.send({ jsonrpc: "2.0", id, method, params });

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`${method} timed out`));
      }, 30000);
      this.pending.set(id, { resolve, reject, timer });
    });
  }

  notify(method, params) {
    this.send({ jsonrpc: "2.0", method, params });
  }

  async start() {
    await this.request("initialize", {
      processId: process.pid,
      rootUri: pathToFileURL(`${root}/`).href,
      capabilities: {
        textDocument: {
          formatting: { dynamicRegistration: false },
        },
      },
      workspaceFolders: [
        {
          uri: pathToFileURL(`${root}/`).href,
          name: basename(root),
        },
      ],
    });
    this.notify("initialized", {});
  }

  async stop() {
    await this.request("shutdown", null);
    this.notify("exit", null);
  }
}

async function collectFishFiles(dir) {
  const files = [];
  const entries = await readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const path = join(dir, entry.name);
    const rel = relative(root, path);

    if (entry.isDirectory()) {
      if (![".git", "node_modules"].includes(entry.name)) {
        files.push(...(await collectFishFiles(path)));
      }
    } else if (
      entry.isFile() &&
      (entry.name.endsWith(".fish") || rel === "run-tests")
    ) {
      files.push(path);
    }
  }

  return files;
}

function lineStarts(text) {
  const starts = [0];
  for (let index = 0; index < text.length; index++) {
    if (text[index] === "\n") {
      starts.push(index + 1);
    }
  }
  return starts;
}

function offsetAt(text, starts, position) {
  if (position.line >= starts.length) {
    return text.length;
  }

  const lineStart = starts[position.line];
  const nextLineStart =
    position.line + 1 < starts.length ? starts[position.line + 1] : text.length;
  return Math.min(lineStart + position.character, nextLineStart);
}

function applyEdits(text, edits) {
  const starts = lineStarts(text);
  return edits
    .map((edit) => ({
      start: offsetAt(text, starts, edit.range.start),
      end: offsetAt(text, starts, edit.range.end),
      newText: edit.newText,
    }))
    .sort((a, b) => b.start - a.start)
    .reduce(
      (updated, edit) =>
        `${updated.slice(0, edit.start)}${edit.newText}${updated.slice(edit.end)}`,
      text,
    );
}

async function formatFile(client, path) {
  const uri = pathToFileURL(path).href;
  const text = await readFile(path, "utf8");

  client.notify("textDocument/didOpen", {
    textDocument: {
      uri,
      languageId: "fish",
      version: 1,
      text,
    },
  });

  const edits = await client.request("textDocument/formatting", {
    textDocument: { uri },
    options: {
      tabSize: 4,
      insertSpaces: true,
    },
  });

  client.notify("textDocument/didClose", {
    textDocument: { uri },
  });

  return edits?.length ? applyEdits(text, edits) : text;
}

const client = new LspClient();
const changed = [];

try {
  await client.start();

  for (const file of (await collectFishFiles(root)).sort()) {
    const before = await readFile(file, "utf8");
    const after = await formatFile(client, file);

    if (after !== before) {
      changed.push(relative(root, file));
      if (!check) {
        await writeFile(file, after);
      }
    }
  }

  await client.stop();
} finally {
  client.process.kill();
}

if (changed.length > 0) {
  if (check) {
    console.error("fish-lsp formatting changes needed:");
    for (const file of changed) {
      console.error(`- ${file}`);
    }
    process.exit(1);
  }

  console.error("Formatted fish files:");
  for (const file of changed) {
    console.error(`- ${file}`);
  }
}
