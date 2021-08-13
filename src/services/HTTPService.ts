import axios, { AxiosRequestConfig } from 'axios';

interface IHTTPHeaders {
    [headerKey: string]: any;
}

interface IQueryPrams {
    [paramName: string]: any;
}

/**
 * Service to manage all HTTP calls.
 */
class HTTPService {
    constructor() {
        axios.interceptors.response.use(
            (response) => Promise.resolve(response),
            (err) => {
                if (!err.response) {
                    return Promise.reject(err);
                }
                const { response } = err;
                return Promise.reject(response);
            }
        );
    }

    /**
     * header object to be append to all api calls.
     */
    private headers: IHTTPHeaders = {
        'content-type': 'application/json',
    };

    /**
     * Sets the headers to the given object.
     */
    public setHeaders(headers: IHTTPHeaders) {
        this.headers = headers;
    }

    /**
     * Adds a header to list of headers.
     */
    public appendHeader(key: string, value: string) {
        this.headers = {
            ...this.headers,
            [key]: value,
        };
    }

    /**
     * Removes the given header.
     */
    public removeHeader(key: string) {
        this.headers[key] = undefined;
    }

    /**
     * Returns axios interceptors.
     */
    // eslint-disable-next-line class-methods-use-this
    public getInterceptors() {
        return axios.interceptors;
    }

    /**
     * Generic HTTP request.
     * This is done so that developer can use any functionality
     * provided by axios. Here, only the set headers are spread
     * over what was sent in config.
     */
    public async request(config: AxiosRequestConfig, customConfig?: any) {
        // eslint-disable-next-line no-param-reassign
        config.headers = {
            ...this.headers,
            ...config.headers,
        };
        if (customConfig?.cancel) {
            config.cancelToken = new axios.CancelToken(
                (c) => (customConfig.cancel.exec = c)
            );
        }
        return await axios({ ...config, ...customConfig });
    }

    /**
     * Get request.
     */
    public get(
        url: string,
        params?: IQueryPrams,
        headers?: IHTTPHeaders,
        customConfig?: any
    ) {
        return this.request(
            {
                headers,
                method: 'GET',
                params,
                url,
            },
            customConfig
        );
    }

    /**
     * Post request
     */
    public post(
        url: string,
        data?: any,
        params?: IQueryPrams,
        headers?: IHTTPHeaders,
        customConfig?: any
    ) {
        return this.request(
            {
                data,
                headers,
                method: 'POST',
                params,
                url,
            },
            customConfig
        );
    }

    /**
     * Put request
     */
    public put(
        url: string,
        data: any,
        params?: IQueryPrams,
        headers?: IHTTPHeaders,
        customConfig?: any
    ) {
        return this.request(
            {
                data,
                headers,
                method: 'PUT',
                params,
                url,
            },
            customConfig
        );
    }

    /**
     * Delete request
     */
    public delete(
        url: string,
        data: any,
        params?: IQueryPrams,
        headers?: IHTTPHeaders,
        customConfig?: any
    ) {
        return this.request(
            {
                data,
                headers,
                method: 'DELETE',
                params,
                url,
            },
            customConfig
        );
    }
}

// Creates a Singleton Service.
// This will help me maintain common headers / functionality
// at a central place.
export default new HTTPService();
