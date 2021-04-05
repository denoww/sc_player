FROM node:14.16.0

# Add contrib packages for ms fonts
RUN echo "deb http://http.debian.net/debian/ stretch main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://http.debian.net/debian/ stretch-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org/ stretch/updates main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update && \
    # Adds required libs for Headless Chrome
    apt-get install -yq gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
    libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
    libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
    libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
    ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget \
    # fonts
    ttf-mscorefonts-installer fontconfig && \
    fc-cache -f

RUN apt-get update && \
    apt-get install -y build-essential clang libdbus-1-dev libgtk-3-dev \
                       libnotify-dev libgnome-keyring-dev \
                       libasound2-dev libcap-dev libcups2-dev libxtst-dev \
                       libxss1 libnss3-dev gcc-multilib g++-multilib curl \
                       gperf bison python-dbusmock openjdk-8-jre \
                       libcanberra-gtk-module libcanberra-gtk3-module \
                       libgtkextra-dev libgconf2-dev

RUN npm install -g electron@12.0.2 --unsafe-perm=true

WORKDIR /src
COPY package*.json ./

# add `/app/node_modules/.bin` to $PATH
ENV PATH /src/node_modules/.bin:$PATH

# To handle 'not get uid/gid'
RUN npm config set unsafe-perm true

RUN npm install --quiet

# EXPOSE 3005
# CMD [ "npm", "run", "start" ]

COPY . .
