export interface Lock {
    wait: Promise<void>;
    unlock(): void;
}
