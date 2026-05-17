#!/usr/bin/env ruby

require "open3"
require "set"
require "yaml"

SENSITIVE_TRIGGERS = %w[
  pull_request_target
  issue_comment
  pull_request_review_comment
  discussion_comment
  workflow_run
].to_set.freeze

WORKFLOW_PATH = %r{\A\.github/workflows/.*\.ya?ml\z}
USES_REF = %r{\A([A-Za-z0-9._-]+/[A-Za-z0-9._-]+(?:/[A-Za-z0-9._/-]+)?)@(\S+)\z}
FULL_SHA = /\A[0-9a-fA-F]{40}\z/

def git(*args)
  stdout, stderr, status = Open3.capture3("git", *args)
  return stdout if status.success?

  abort(stderr.empty? ? "git #{args.join(' ')} failed" : stderr)
end

def blob(revision, path)
  stdout, _stderr, status = Open3.capture3("git", "show", "#{revision}:#{path}")
  status.success? ? stdout : ""
end

def workflow_changes(base, head)
  git("diff", "--name-status", "--find-renames", "--diff-filter=AMR", "#{base}...#{head}")
    .lines
    .each_with_object([]) do |line, changes|
      status, path, new_path = line.chomp.split("\t")
      head_path = status.start_with?("R") ? new_path : path
      next unless head_path.match?(WORKFLOW_PATH)

      base_path = status.start_with?("R") && path.match?(WORKFLOW_PATH) ? path : head_path
      changes << { base: base_path, head: head_path }
    end
end

def workflow_yaml(revision, path)
  YAML.safe_load(
    blob(revision, path),
    aliases: true,
  ) || {}
rescue Psych::Exception => e
  abort("Failed to parse workflow YAML in #{revision}:#{path}: #{e.message}")
end

def trigger_names(workflow)
  events = workflow["on"] || workflow[true]
  return [events] if events.is_a?(String)
  return events.grep(String) if events.is_a?(Array)
  return events.keys.map(&:to_s) if events.is_a?(Hash)

  []
end

def uses_values(node)
  case node
  when Hash
    node.flat_map do |key, value|
      [key.to_s == "uses" && value.is_a?(String) ? value : nil, *uses_values(value)]
    end.compact
  when Array
    node.flat_map { |value| uses_values(value) }
  else
    []
  end
end

def workflow_facts(revision, path)
  workflow = workflow_yaml(revision, path)
  triggers = trigger_names(workflow).to_set & SENSITIVE_TRIGGERS
  unpinned_actions = uses_values(workflow).each_with_object(Set.new) do |uses, actions|
    action, ref = uses.match(USES_REF)&.captures
    next unless action
    next if action.start_with?("actions/") || ref.match?(FULL_SHA)

    actions.add("#{action}@#{ref}")
  end

  { triggers: triggers, unpinned_actions: unpinned_actions }
end

base, head = ARGV
abort("Usage: #{$PROGRAM_NAME} <base-revision> <head-revision>") unless base && head

changes = workflow_changes(base, head)
if changes.empty?
  puts "Workflow Security Checks: Passed"
  puts "No workflow files changed."
  exit 0
end

trigger_violations = []
unpinned_violations = []

changes.each do |change|
  path = change[:head]
  before = workflow_facts(base, change[:base])
  after = workflow_facts(head, path)

  (after[:triggers] - before[:triggers]).each do |trigger|
    trigger_violations << "#{path}: #{trigger}"
  end

  (after[:unpinned_actions] - before[:unpinned_actions]).each do |action|
    unpinned_violations << "#{path}: #{action}"
  end
end

failed = trigger_violations.any? || unpinned_violations.any?
puts "Workflow Security Checks: #{failed ? "Failed" : "Passed"}"
puts
puts "Checked workflow files:"
changes.each do |change|
  rename = change[:base] == change[:head] ? "" : " (renamed from #{change[:base]})"
  puts "- #{change[:head]}#{rename}"
end

exit 0 unless failed

unless trigger_violations.empty?
  puts
  puts "New privileged triggers:"
  trigger_violations.each { |violation| puts "- #{violation}" }
end

unless unpinned_violations.empty?
  puts
  puts "New unpinned third-party actions:"
  unpinned_violations.each { |violation| puts "- #{violation}" }
end

puts
puts "Fix:"
puts "- Remove newly added privileged triggers." if trigger_violations.any?
puts "- Pin third-party actions to a full 40-character commit SHA." if unpinned_violations.any?
exit 1
