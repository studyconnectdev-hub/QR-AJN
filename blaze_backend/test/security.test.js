import test from 'node:test';
import assert from 'node:assert/strict';
import {isPrivateIp} from '../src/security.js';

test('blocks private IPv4 ranges', () => {
  assert.equal(isPrivateIp('127.0.0.1'), true);
  assert.equal(isPrivateIp('10.1.2.3'), true);
  assert.equal(isPrivateIp('192.168.1.4'), true);
  assert.equal(isPrivateIp('8.8.8.8'), false);
});

test('blocks loopback and local IPv6', () => {
  assert.equal(isPrivateIp('::1'), true);
  assert.equal(isPrivateIp('fd00::1'), true);
  assert.equal(isPrivateIp('2606:4700:4700::1111'), false);
});
