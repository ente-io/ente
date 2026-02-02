import React from "react";

type Variant = "primary" | "text";
type Tone = "default" | "danger";

export type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: Variant;
  tone?: Tone;
  fullWidth?: boolean;
};

function cn(...parts: Array<string | undefined | null | false>) {
  return parts.filter(Boolean).join(" ");
}

export default function Button({
  variant = "text",
  tone = "default",
  fullWidth = false,
  className,
  ...props
}: ButtonProps) {
  const base =
    "rounded-lg transition-colors disabled:cursor-not-allowed disabled:opacity-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--ente-accent)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--ente-background)]";

  if (variant === "primary") {
    return (
      <button
        {...props}
        className={cn(
          base,
          fullWidth && "w-full",
          // Primary actions are intentionally larger/bolder.
          "py-2.5 px-4 bg-[var(--ente-accent)] hover:bg-[var(--ente-accent-700)] text-white text-base font-bold",
          // In light theme, a white disabled label on a near-white disabled bg looks invisible.
          "disabled:bg-[var(--ente-paper-2)] disabled:text-[var(--ente-text-faint)] disabled:opacity-100",
          className,
        )}
      />
    );
  }

  return (
    <button
      {...props}
      className={cn(
        base,
        fullWidth && "w-full",
        // Text buttons should read like links (no filled hover background).
        "py-2 px-3 text-sm font-medium",
        tone === "danger"
          ? "text-[var(--ente-text-muted)] hover:text-red-500"
          : "text-[var(--ente-text-muted)] hover:text-[var(--ente-text)]",
        className,
      )}
    />
  );
}
