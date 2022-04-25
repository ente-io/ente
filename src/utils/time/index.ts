export interface TimeDelta {
    hours?: number;
    days?: number;
    months?: number;
    years?: number;
}

export function dateStringWithMMH(unixTimeInMicroSeconds: number): string {
    return new Date(unixTimeInMicroSeconds / 1000).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
}

export function getUnixTimeInMicroSecondsWithDelta(delta: TimeDelta): number {
    let currentDate = new Date();
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
    return currentDate.getTime() * 1000;
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

export function parseDateTime(dateTimeString: string) {
    let year = 0;
    let month = 0;
    let day = 0;
    let hour = 0;
    let min = 0;
    let sec = 0;
    let date;
    let time;

    if (dateTimeString.length > 15) {
        dateTimeString = dateTimeString.slice(0, 15);
    }
    if (dateTimeString.includes('T')) {
        [date, time] = dateTimeString.split('T');
    } else {
        date = dateTimeString.slice(0, 8);
    }

    if (date?.length === 8) {
        year = parseInt(dateTimeString.slice(0, 4));
        month = parseInt(dateTimeString.slice(4, 6)) - 1;
        day = parseInt(dateTimeString.slice(6, 8));
    }
    if (time?.length === 6) {
        hour = parseInt(time.slice(0, 2));
        min = parseInt(time.slice(2, 4));
        sec = parseInt(time.slice(4, 6));
    }
    const parsedDate = new Date(year, month, day, hour, min, sec);
    return getUnixTimeInMicroSeconds(parsedDate);
}
