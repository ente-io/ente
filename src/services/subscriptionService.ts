import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import HTTPService from './HTTPService';

const ENDPOINT = getEndpoint();
const token = getToken();
class SubscriptionService {
    async getUsage() {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/billing/usage`,
                { startTime: 0, endTime: Date.now() * 1000 },
                {
                    'X-Auth-Token': token,
                }
            );
            return this.convertBytesToGBs(response.data.usage);
        } catch (e) {
            console.error('error getting usage', e);
        }
    }

    public convertBytesToGBs(bytes): string {
        return (bytes / (1024 * 1024 * 1024)).toFixed(2);
    }
}

export default new SubscriptionService();
