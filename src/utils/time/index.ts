export interface TimeDetla {
    hours?: number;
    days?: number;
    months?: number;
    years?: number;
}

export function getUnixTimeInMicroSecondsWithDelta(delta: TimeDetla): number {
    let currentDate = new Date();
    console.log(currentDate);
    console.log(currentDate.getUTCMilliseconds());
    if (delta?.hours) {
        currentDate = _addHours(currentDate, delta.hours);
    }
    if (delta?.days) {
        currentDate = _addDays(currentDate, delta.days);
    }
    if (delta?.months) {
        currentDate = _addMonth(currentDate, delta.months);
    }
    if (delta?.years) {
        currentDate = _addYears(currentDate, delta.years);
    }
    return currentDate.valueOf() * 1000;
}

export function getUnixTimeInMicroSeconds(dateTime: Date) {
    if (!dateTime || isNaN(dateTime.getTime())) {
        return null;
    }
    const unixTime = dateTime.getTime() * 1000;
    if (unixTime <= 0) {
        return null;
    } else {
        return unixTime;
    }
}

function _addDays(date: Date, days: number): Date {
    const result = new Date(date);
    result.setDate(date.getDate() + days);
    return result;
}

function _addHours(date: Date, hours: number): Date {
    const result = new Date(date);
    result.setHours(date.getHours() + hours);
    return result;
}

function _addMonth(date: Date, months: number) {
    const result = new Date(date);
    result.setMonth(date.getMonth() + months);
    return result;
}

function _addYears(date: Date, years: number) {
    const result = new Date(date);
    result.setFullYear(date.getFullYear() + years);
    return result;
}
