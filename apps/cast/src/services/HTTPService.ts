import axios, { AxiosRequestConfig, AxiosResponse } from 'axios';
import { addLogLine } from 'utils/logging';
import { logError } from 'utils/sentry';
import { ApiError, CustomError, isApiErrorResponse } from 'utils/error';

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
            (error) => {
                const config = error.config as AxiosRequestConfig;
                if (error.response) {
                    const response = error.response as AxiosResponse;
                    let apiError: ApiError;
                    // The request was made and the server responded with a status code
                    // that falls out of the range of 2xx
                    if (isApiErrorResponse(response.data)) {
                        const responseData = response.data;
                        logError(error, 'HTTP Service Error', {
                            url: config.url,
                            method: config.method,
                            xRequestId: response.headers['x-request-id'],
                            httpStatus: response.status,
                            errMessage: responseData.message,
                            errCode: responseData.code,
                        });
                        apiError = new ApiError(
                            responseData.message,
                            responseData.code,
                            response.status
                        );
                    } else {
                        if (response.status >= 400 && response.status < 500) {
                            apiError = new ApiError(
                                CustomError.CLIENT_ERROR,
                                '',
                                response.status
                            );
                        } else {
                            apiError = new ApiError(
                                CustomError.ServerError,
                                '',
                                response.status
                            );
                        }
                    }
                    logError(apiError, 'HTTP Service Error', {
                        url: config.url,
                        method: config.method,
                        cfRay: response.headers['cf-ray'],
                        xRequestId: response.headers['x-request-id'],
                        httpStatus: response.status,
                    });
                    throw apiError;
                } else if (error.request) {
                    // The request was made but no response was received
                    // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
                    // http.ClientRequest in node.js
                    addLogLine(
                        'request failed- no response',
                        `url: ${config.url}`,
                        `method: ${config.method}`
                    );
                    return Promise.reject(error);
                } else {
                    // Something happened in setting up the request that triggered an Error
                    addLogLine(
                        'request failed- axios error',
                        `url: ${config.url}`,
                        `method: ${config.method}`
                    );
                    return Promise.reject(error);
                }
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
        this.headers = {
            ...this.headers,
            ...headers,
        };
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
