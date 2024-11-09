export interface TimeDelta {
    hours?: number;
    days?: number;
    months?: number;
    years?: number;
}

export function getUnixTimeInMicroSecondsWithDelta(delta: TimeDelta): number {
    let date = new Date();
    if (delta?.hours) {
        date = new Date(date.getTime() + delta.hours * 60 * 60 * 1000);
    }
    if (delta?.days) {
        date.setDate(date.getDate() + delta.days);
    }
    if (delta?.months) {
        date.setMonth(date.getMonth() + delta.months);
    }
    if (delta?.years) {
        date.setFullYear(date.getFullYear() + delta.years);
    }
    return date.getTime() * 1000;
}
