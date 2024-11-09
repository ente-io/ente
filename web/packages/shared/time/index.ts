export interface TimeDelta {
    hours?: number;
    days?: number;
    months?: number;
    years?: number;
}

export function getUnixTimeInMicroSecondsWithDelta(delta: TimeDelta): number {
    let date = new Date();
    if (delta?.hours) {
        date = _addHours(date, delta.hours);
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

function _addHours(date: Date, hours: number): Date {
    const result = new Date(date);
    result.setHours(date.getHours() + hours);
    return result;
}
