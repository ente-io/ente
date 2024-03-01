import { Entity } from "types/entity";

export const getLatestVersionEntities = <T>(entities: Entity<T>[]) => {
    const latestVersionEntities = new Map<string, Entity<T>>();
    entities.forEach((entity) => {
        const existingEntity = latestVersionEntities.get(entity.id);
        if (!existingEntity || existingEntity.updatedAt < entity.updatedAt) {
            latestVersionEntities.set(entity.id, entity);
        }
    });
    return Array.from(latestVersionEntities.values());
};
