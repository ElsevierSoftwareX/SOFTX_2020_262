![EchoAnalysis_tot.png](https://bitbucket.org/yladroit/esp3/raw/master/icons/EchoAnalysis_tot.png)

ESP3 is an **open-source** software for visualizing and processing **fisheries acoustics data**, developed by the fisheries acoustics team at NIWA (Wellington, New Zealand). Its focus is the processing of fisheries acoustic surveys, with attention to reproducibility and consistency. It is built in priority for SIMRAD EK60 and EK80 data (.raw) but also supports a few other formats to some extent (NIWA CREST, Furuno FCV-30 and ASL AZFP).

ESP3 includes standard data processing procedures such as calibration and echo-integration, and many algorithms including bad pings identification, automated bottom detection, single targets identification and tracking, schools detection and classification, etc. 

ESP3 is currently under active development (particularly in terms of broadband processing).

**[See the wiki for more information on ESP3 features.]( https://bitbucket.org/yladroit/esp3/wiki ) **

---

## Getting Started

ESP3 is written in **MATLAB**. Provided you have a licence for the appropriaate version of MATLAB (R2019b or later) and required toolboxes, these instructions will get you a copy of the source code to get ESP3 up and running on your local machine for development and testing purposes.

See the section "Software Download"" for notes on how to install a compiled version on a Windows 64bits platform.

### Prerequisites

* **MATLAB R2019b** (or more recent).

* **Licenced MATLAB toolboxes**: 
    * Signal Processing
    * Image Processing
    * Statistics and Machine Learning
    * Curve Fitting
	
* **Installed MATLAB toolboxes**:
    * Database (needs to be installed to have access to the sqlite functionnality of MATLAB, but MATLAB does not require a licence for the use of the sqlite embedded function...)
	
* [Git](https://git-scm.com/downloads) and [Git Large File Storage (Git LFS)](https://git-lfs.github.com/). 
    * Note that instead of installing those stand-alone versions, you can simply download and use a Git client that will install them for you. We use and recommend [Sourcetree](https://www.sourcetreeapp.com/).
    * If you don't know Git yet, [learn about it and version controlling here](https://www.atlassian.com/git?utm_source=bitbucket&utm_medium=link&utm_campaign=help_dropdown&utm_content=learn_git).

### Installing

Clone the ESP3 repository and check it out (download) on your machine. 

Once you have the repository on your machine, open MATLAB, make the "ESP3" root folder your current directory, and run the software with the command ```EchoAnalysis```

---

## Running the tests

NA

---

## Software download

A compiled version of the latest stable release is available for install on a Windows 64bits platform. It does not require any MATLAB licence.

### Prerequisites

* Download and install the (free) [Matlab Compiler Runtime R2019b (9.7)](https://au.mathworks.com/products/compiler/matlab-runtime.html). 

### Installing

* Download the latest installer for the ESP3 compiled version on SourceForge:

[![Download ESP3](https://a.fsdn.com/con/app/sf-download-button)](https://sourceforge.net/projects/esp3/files/latest/download)

Note: Earlier compiled versions are also available [here](https://sourceforge.net/projects/esp3/files/).

* Run the installer and follow the instructions.

---

## More information

**[See the wiki for manuals (user, technical, tutorials) currently in development.](https://bitbucket.org/yladroit/esp3/wiki/Home)**

---

## License

Copyright 2017 NIWA

This project is licensed under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## Authors

* **Yoann Ladroit**, NIWA - *Initial work and main developer* - Yoann.ladroit@niwa.co.nz - [yladroit](https://bitbucket.org/yladroit)
* **Alexandre C.G. Schimel**, NIWA  - *Developer* - Alexandre.Schimel@niwa.co.nz - [AlexandreSchimel](https://bitbucket.org/AlexandreSchimel)
* **Pablo Escobar-Flores**,NIWA - *Developer* - Pablo.Escobar@niwa.co.nz - [Pabloe1982](https://bitbucket.org/Pabloe1982)

---

## FAQ

* **How do I stay up-to-date with the latest developments? Do I have to re-download a new version every time it comes out?**

For the compiled version, yes. For the MATLAB version, Git will allow you to keep it updated to the latest version.

* **I would like to code my own MATLAB algorithms and extensions for ESP3. Can I do it?**

Yes. Fork the project using Git and develop it on your side. Your changes will stay on your copy, without affecting the development of the main branch. You can always integrate the latest changes made on the main branch back into your forked copy (see Git functions "sync" and "merge").

If down the line you wish to suggest to integrate parts of your code to the main branch, you can do that too using "pull requests" in Git.

* **I would like to help developing the main branch. Can I join the development team?**

With pleasure. Contact the authors.