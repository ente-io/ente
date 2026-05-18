let email = "";
let token = "";

export const setEmail = (newEmail: string) => {
    email = newEmail;
};

export const setToken = (newToken: string) => {
    token = newToken;
};

export const getEmail = () => email;
export const getToken = () => token;
